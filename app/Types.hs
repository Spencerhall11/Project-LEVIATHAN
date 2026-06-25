module Types where

--| User trust tiers
data TrustTier
    = Unrecognized
    | GrudgingYield
    | RecognizedPilot
    | Admiral
    | PackLeader
    | Creator
    deriving (Show,Eq,Ord)

--| Tracks passed trials
data TrialRecord = TrialRecord
    { vocalCipherPassed :: Bool
    , endurancePassed   :: Bool
    , tyrTrialPassed    :: Bool
    } deriving (Show, Eq)

--| Persistent user profiles saved across sessions
data UserProfile = UserProfile
    { userId                    :: String
    , affinityScore             :: Double
    , tier                      :: TrustTier
    , trials                    :: TrialRecord
    , faceEmbedding             :: [Double]
    , voicePrint                :: [Double]
    , passcode                  :: String 
    , totalInterventionTime     :: Double
    } deriving (Show,Eq)

--| Head identifiers
data HeadId = Fafnir | Jormungandr
    deriving (Show,Eq)

--|Registration for new users
data RegistrationState
    = WaitingForCipher
    | CipherValidated
    | AwaitingBiometrics
    deriving (Show, Eq)

--| Hardware events from Rust layer
data HardwareEvent
    = RigWorn
    | RigRemoved
    | ImpactSurge
    | LoadLimitBreached
    | FrameStabilized
    deriving (Show, Eq)

--| Current session authentication
data SessionState
    = Anonymous
    | Registering String RegistrationState
    | Authenticated UserProfile
    deriving (Show, Eq)
