"""Run real addon modules on Lua 5.1 across every supported client family."""
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if os.environ.get("HOURSTONE_TEST_DEPS"):
    sys.path.insert(0, os.environ["HOURSTONE_TEST_DEPS"])
from lupa.lua51 import LuaRuntime

def runtime(project=1, locale="deDE", backdrop=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().TEST_LOCALE = locale
    lua.globals().WOW_PROJECT_ID = project
    lua.globals().BackdropTemplateMixin = lua.table() if backdrop else None
    lua.execute((ROOT / "tests/wow_mock.lua").read_text(encoding="utf-8"))
    lua.execute("H={}")
    loader = lua.eval('function(code,name) local f,e=loadstring(code,name); assert(f,e); f("Hourstone",H) end')
    for line in (ROOT / "Hourstone/Hourstone.toc").read_text().splitlines():
        if line.endswith(".lua"):
            loader((ROOT / "Hourstone" / line).read_text(encoding="utf-8"), line)
    return lua

def main():
    tests = sorted((ROOT / "tests").glob("test_*.lua"))
    count = 0
    for project, locale in [(1,"deDE"),(19,"enUS"),(5,"deDE"),(2,"enUS"),(999,"frFR")]:
        for backdrop in [True, False]:
            for test in tests:
                lua = runtime(project, locale, backdrop)
                try:
                    lua.execute(test.read_text(encoding="utf-8"))
                except Exception as exc:
                    raise RuntimeError(f"{test.name}, project={project}, locale={locale}, backdrop={backdrop}: {exc}") from exc
                count += 1
        print(f"PASS project={project}, locale={locale}: native + fallback frames")
    print(f"PASS {count} scenario suites; actual WoW client testing remains pending.")

if __name__ == "__main__":
    main()
