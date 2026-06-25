module StateMachine where

import Types

-- | The behavioral states each head can be in independently
data RigState
    = VanguardHorizon        -- standby, slow idle sway, scanning
    | TrialWindow Double     -- active trial, Double is seconds remaining
    | FullCompliance         -- recognized pilot, fluid tracking
    | GrudgingMode           -- failed trial, dampened and resistant
    | PosturalLockdown       -- critical safety, fully retracted
    | StartleLoop            -- brief freeze, resumes after settling
    | Tantrum                -- annoyance threshold crossed, acting out
    | ForcedTrial            -- rig initiated trial independently
    deriving (Show, Eq)

-- | The complete state of one head at any moment
data HeadState = HeadState
    { headId        :: HeadId
    , rigState      :: RigState
    , annoyance     :: Double    -- builds toward Tantrum
    , volatility    :: Double    -- builds toward ForcedTrial
    , packLeader    :: Maybe String  -- userId of this head's PackLeader if assigned
    } deriving (Show, Eq)

-- | The full rig is two independent heads
data Leviathan = Leviathan
    { fafnir        :: HeadState
    , jormungandr   :: HeadState
    , sessionState  :: SessionState
    } deriving (Show, Eq)


-- | Events that can trigger state transitions
data RigEvent
    -- Authentication events
    = CipherSpoken String        -- the spoken cipher attempt, carries the text
    | CheckInSpoken String       -- "I am [name]" carries the claimed identity
    | RegisterCommand String     -- "Register new pilot: [name]"
    | BiometricsConfirmed        -- Python layer confirms face and voice match
    | BiometricsFailed           -- Python layer rejects the match

    -- Trial events
    | TrialDeclared              -- wearer voluntarily declares a trial
    | TrialFailed                -- wearer yielded or was knocked down
    | TrialPassed                -- wearer endured successfully
    | NearMiss                   -- cipher almost correct
    | TyrHandPlaced              -- hand placed in jaw
    | TyrHandHeld                -- held steady, Tyr trial passed
    | TyrHandFlinched            -- flinched, Tyr trial failed

    -- Environmental events
    | TargetDetected String      -- vision pipeline detected someone
    | SpaceConfirmed             -- enough room for forced trial
    | SpaceTooTight              -- not enough room for forced trial

    -- Hardware events
    | Hardware HardwareEvent     -- wraps events from Rust layer

    -- Internal events
    | AnnoyanceThresholdCrossed  -- annoyance meter maxed
    | VolatilityThresholdCrossed -- volatility meter maxed
    | TimerTick Double           -- countdown tick for trial window
    | StartleDetected            -- vision detected a flinch
    | StartleResolved            -- rig has settled after startle

    -- Passcode fallback for altered appearance
    | FaceConfirmationFailed     -- face recognition failed
    | PasscodeSubmitted String   -- carries the submitted passcode
    | PasscodeAccepted           -- passcode matched the profile
    | PasscodeRejected           -- passcode did not match
    deriving (Show, Eq)


-- | Transition a single head based on an event
transition :: HeadState -> SessionState -> RigEvent -> HeadState

-- Safety always takes priority regardless of current state
transition head _ (Hardware ImpactSurge)       = head { rigState = PosturalLockdown }
transition head _ (Hardware LoadLimitBreached) = head { rigState = PosturalLockdown }
transition head _ (Hardware RigRemoved)        = head { rigState = VanguardHorizon }

-- Startle loop interrupts any non-lockdown state briefly
transition head _ StartleDetected = head { rigState = StartleLoop }
transition head _ StartleResolved = head { rigState = VanguardHorizon }

-- Annoyance and volatility thresholds
transition head _ AnnoyanceThresholdCrossed  = head { rigState = Tantrum }
transition head _ VolatilityThresholdCrossed = head { rigState = ForcedTrial }

-- Trial window countdown
transition head session (TimerTick dt) =
    case rigState head of
        TrialWindow t ->
            if t - dt <= 0
                then head { rigState = GrudgingMode }  -- time ran out
                else head { rigState = TrialWindow (t - dt) }
        _ -> head  -- timer ticks ignored outside trial window

-- Trial outcomes
transition head _ TrialPassed = head { rigState = FullCompliance
                                     , annoyance = 0
                                     , volatility = 0 }
transition head _ TrialFailed = head { rigState = GrudgingMode }

-- Tyr trial
transition head _ TyrHandHeld     = head  -- handled in Affinity layer
transition head _ TyrHandFlinched = head 
    { annoyance  = annoyance head + 40.0
    , volatility = volatility head + 25.0
    }

-- Default -- unhandled event changes nothing
transition head _ _ = head