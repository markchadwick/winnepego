HAXE=/usr/bin/haxe

.PHONY: test
test:
	$(HAXE) \
	  	--interp \
	  	-cp src \
	  	-cp test \
	  	-main winnepego.Test

.PHONY: run
run:
	$(HAXE) \
   --interp \
   -cp src \
   -cp test \
   -main winnepego.Main

compiler.js:
	$(HAXE) \
	  	-cp src \
	  	-cp test \
      -js compiler.js \
      winnepego.TestWKT
