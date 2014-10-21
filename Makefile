ocamlbuild := ocamlbuild -use-ocamlfind # -classic-display -j 1


all := all.otarget

all: 
	$(ocamlbuild) $(all)

