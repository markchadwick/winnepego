HAXE=/usr/bin/haxe
# HAXE=/home/mchadwick/opt/haxe-3.1.3/haxe-3.1.3/haxe
# HAXE_STD_PATH=/home/mchadwick/opt/haxe-3.1.3/haxe-3.1.3/std

.PHONY: test
test:
	# @HAXE_STD_PATH=$(HAXE_STD_PATH)
	$(HAXE)\
	  	--interp \
	  	-cp src \
	  	-cp test \
	  	-main winnepego.Test

.PHONY: run
run:
	@HAXE_STD_PATH=$(HAXE_STD_PATH) \
	$(HAXE) \
   --interp \
   -cp src \
   -cp test \
   -main winnepego.Main

compiler.py:
	$(HAXE)\
	  	-cp src \
	  	-cp test \
      -python compiler.py \
      winnepego.Main

compiler.js:
	HAXE_STD_PATH=$(HAXE_STD_PATH) \
	$(HAXE)\
	  	-cp src \
	  	-cp test \
      -js compiler.js \
      winnepego.Main
