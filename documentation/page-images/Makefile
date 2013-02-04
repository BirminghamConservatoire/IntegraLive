all: shadow-stamp

shadow-stamp:
	touch shadow-stamp	
	for i in *.png; do convert $$i '(' +clone -background black -shadow 80x3+3+3 ')' +swap -background none -layers merge +repage shadow-$$i; done
		
clean:
	@rm shadow-*
