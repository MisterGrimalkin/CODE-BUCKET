if [ "$2" = "-real" ]
then
	rename 's/\./'$1'\./' *
else
	rename -n 's/\./'$1'\./' *
fi
