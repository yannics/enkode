form enkode analysis
    sentence soundfile 
    sentence textgrid 
comment The segmentation has to be on the first tier of the textgrid 
comment and named as ordered integers from 1 until the total number of events.
	boolean enkode_analysis 0
    positive fcut 100
    positive foss 500
	boolean spectrum_analysis 0
comment The spectrum analysis is done on 116 bins from 0 to 5000 Hz as re(Pa/Hz).
	boolean reframe_TextGrid 0
	sentence keyword_(ignore_interval)
	boolean overwrite_TextGrid 0
endform
filedelete 'defaultDirectory$'/spectrum.dat
filedelete 'defaultDirectory$'/enkode.dat
# ---------------------------------
procedure get_first_partial
	i = 1
    up = 0
	f0 = 0
    nbs = Get number of bins
	repeat
		val1 = Get real value in bin: 'i'
		val2 = Get real value in bin: 'i'+1
		i = i + 1
	    if 'val1' - 'val2' > 0 and 'up' = 0
		    up = 0
        else
            up = 1
        endif
		if 'val1' > 'val2' and 'up' = 1 and 'f0' = 0
		    f0 = Get frequency from bin number: 'i'-1
		endif
	until 'i' = 'nbs'
endproc
# ---------------------------------
procedure mk_spectrum
	i = 1
    val=0
	step=1
	div=1
    nbs = Get number of bins
	repeat
		val1 = Get real value in bin: 'i'
		fi = Get frequency from bin number: 'i'
		i = 'i' + 1
        fact=(5000/116) * 'step'
	    if 'fi' > 'fact'   
			res=('val1' + 'val')/'div' 
			fileappend 'defaultDirectory$'/spectrum.dat 'res' 
			val = 'val1'
  			div=1
			step = 'step' + 1
        else
            val ='val1' + 'val'
			div='div'+1
        endif
	until 'step' = 116+1
endproc
# ---------------------------------
procedure mk_loudness .sound$
	select Sound '.sound$'
	To Cochleagram: 0.01, 0.1, 0.03, 0.03
	res = 0
	tps = 0
	i = 1
	while 'tps' < 'duration'
		select Cochleagram '.sound$'
		To Excitation (slice): 'tps'
		loudness = Get loudness
        if (loudness = undefined)
    	        loudness = 1.6
        endif
		array [i] = 'loudness'
		tps = 'tps' + 0.01
		i = 'i' + 1
	endwhile
	sumnum = 0
	sumden = 0
	rev = 'i' 
	for a from 1 to 'i'-1
		sumnum = 'sumnum' + (array['a'] * ('rev'-'a'))
		sumden = 'sumden' + 'a'
		select Excitation '.sound$'
		Remove
	endfor
	res = sumnum/sumden
	select Cochleagram '.sound$'
	Remove
	select Sound '.sound$'
	Remove
endproc
# ---------------------------------
Read from file... 'soundfile$'
current_sound$ = selected$ ("Sound")

if (textgrid$ == "")
	To TextGrid: "a", "b"
	Set interval text: 1, 1, "1"
	current_textgrid$ = selected$ ("TextGrid")
	n = 1
else
	Read from file... 'textgrid$'
	current_textgrid$ = selected$ ("TextGrid")
	select TextGrid 'current_textgrid$'
	n = Count intervals where: 1, "is not equal to", ""
# ---------------------------------
	if (reframe_TextGrid = 1)
		select TextGrid 'current_textgrid$'
		Duplicate tier: 1, 1, ""
		x = Get number of intervals: 1
		label$="0"
		strings = Create Strings as tokens: keyword$, ","
		numberOfStrings = Get number of strings
		for xx from 1 to x
			name$ = Get label of interval: 1, xx
			 for istring to numberOfStrings
    			selectObject: strings
    			stringName$ = Get string: istring
  				if (keyword$ = stringName$)
					Set interval text: 1, nn, ""
				else
					label$=string$(number(label$)+1)
					Set interval text: 1, xx, label$ 
				endif
			endfor
		endfor
		if (overwrite_TextGrid = 1)
			Save as short text file: textgrid$
		else
			rename$ = textgrid$ - ".TextGrid" + "-reframed.TextGrid"
			Save as short text file: rename$
			Read from file... 'rename$'
			current_textgrid$ = selected$ ("TextGrid")
		endif
	endif
# ---------------------------------
endif
for nn from 1 to n
	select Sound 'current_sound$'
	plus TextGrid 'current_textgrid$'
	Extract intervals where: 1, "no", "is equal to", "'nn'"
	duration = Get total duration
    do ("To Spectrum...", "yes")
	centroid = Get centre of gravity... 2
	if (centroid = undefined)
		centroid = 'fcut'/2 # this is completely arbitrary
	endif
	Cepstral smoothing: 'foss'
# ---------------------------------
	if (spectrum_analysis = 1)
		call mk_spectrum
		fileappend 'defaultDirectory$'/spectrum.dat 'newline$'
	endif
# ---------------------------------
	if (enkode_analysis = 1)
		call get_first_partial
		if (f0 = 0)
			f0 = 'fcut'/2 # this is completely arbitrary
		endif
		select Spectrum 'current_sound$'_'nn'_1
		Remove
		select Spectrum 'current_sound$'_'nn'_1
		Remove
		select Sound 'current_sound$'_'nn'_1
		Rename: "event"
		Filter (stop Hann band): 100, 0, 50
		Rename: "bass"
		call mk_loudness bass
		loudbass = res		
		call mk_loudness event
		loudness = res		
		appendFileLine("enkode.dat", 'duration', " ", 'f0', " ", 'centroid', " ", 'loudness', " ", 'loudbass')
    endif
endfor
select all
Remove