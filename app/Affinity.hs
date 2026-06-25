module Affinity where

import Types

-- | Events that affect affinity
data AffinityEvent
    = TrialSuccess
    | DefiantFailure      -- failed but refused to yield
    | ComfortableYield    -- gave up easily
    | TyrSuccess
    | TyrFlinch
    | CipherMistake
    | SessionCompleted
    deriving (Show, Eq)

-- | PackLeader thresholds per head
packLeaderAffinityThreshold :: HeadId -> Double
packLeaderAffinityThreshold Fafnir     = 175.0
packLeaderAffinityThreshold Jormungandr = 150.0

packLeaderTimeThreshold :: HeadId -> Double
packLeaderTimeThreshold Fafnir      = 108000.0  
packLeaderTimeThreshold Jormungandr = 180000.0

-- | Affinity cap and buffer boundary
affinityCap :: Double
affinityCap = 100.0

-- | Check if a user qualifies for PackLeader on a specific head
isPackLeaderEligible :: HeadId -> UserProfile -> Bool
isPackLeaderEligible hid profile =
    allTrialsPassed (trials profile)
    && affinityScore profile >= packLeaderAffinityThreshold hid
    && totalInteractionTime profile >= packLeaderTimeThreshold hid

-- | Check all three trials are completed
allTrialsPassed :: TrialRecord -> Bool
allTrialsPassed t =
    vocalCipherPassed t
    && endurancePassed t
    && tyrTrialPassed t

-- | Apply affinity change, respecting cap and buffer
adjustAffinity :: Double -> Double -> Double
adjustAffinity current delta = max 0.0 (current + delta)

-- | Affinity gains per event
affinityGain :: HeadId -> AffinityEvent -> Double
affinityGain hid TrialSuccess        = case hid of
    Fafnir      -> 20.0   -- Fafnir rewards success dramatically
    Jormungandr -> 12.0   -- Jormungandr more measured
affinityGain hid DefiantFailure      = case hid of
    Fafnir      -> 10.0   -- respects the nerve even in failure
    Jormungandr -> 8.0
affinityGain hid TyrSuccess          = case hid of
    Fafnir      -> 15.0
    Jormungandr -> 15.0   -- both heads value this equally
affinityGain _   ComfortableYield    = 0.0    -- no respect for easy surrender
affinityGain hid SessionCompleted    = case hid of
    Fafnir      -> 2.0    -- passive time gain
    Jormungandr -> 2.0

-- | Affinity losses per event
affinityLoss :: HeadId -> AffinityEvent -> Double
affinityLoss hid TyrFlinch           = case hid of
    Fafnir      -> 20.0   -- Fafnir takes deep offense
    Jormungandr -> 20.0
affinityLoss hid CipherMistake       = case hid of
    Fafnir      -> 8.0    -- Fafnir less forgiving of mistakes
    Jormungandr -> 5.0
affinityLoss _   ComfortableYield    = 10.0
affinityLoss _   _                   = 0.0
