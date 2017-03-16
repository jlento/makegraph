SHELL=/bin/bash

include jobs.make

.PHONY : clean

%-input.nc :
	cat $^ > $@

%-output.nc :
	cp $< $@

jobs.make :
	$(SHELL) depsgen.bash > jobs.make

clean :
	rm -f deps-*
