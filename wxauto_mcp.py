"""Development entry point — delegates to wxauto_mcp.server."""

from wxauto_mcp.server import mcp

if __name__ == "__main__":
    mcp.run()
