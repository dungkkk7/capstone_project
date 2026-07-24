"""Reproducible P0/A0/B0 experiment harness.

The harness deliberately lives beside the legacy pipeline.  P0 continues to
use its existing iterative recovery protocol, while A0 and B0 use the
one-shot protocol implemented in this package.
"""

from .enums import MethodId, Stage, TerminalStatus
from .models import SampleIdentity, VariantResult

__all__ = [
    "MethodId",
    "SampleIdentity",
    "Stage",
    "TerminalStatus",
    "VariantResult",
]
