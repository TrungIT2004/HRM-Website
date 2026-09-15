from abc import ABC, abstractmethod
from pathlib import Path
from src.models.schema import ParsedDocument


class BaseParser(ABC):
    """Abstract base class for all file parsers."""

    @abstractmethod
    def parse(self, file_path: Path | str) -> ParsedDocument:
        """Parse the input document into structured blocks."""
        pass
