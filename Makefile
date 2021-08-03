all: lua/editorconfig.lua

clean:
	rm -f lua/*.lua

lua/%.lua: fnl/%.fnl
	fennel --compile $< > $@

.PHONY: all clean
