form Analysis
    sentence soundfile 
    sentence textgrid 
comment The segmentation has to be on the first tier of the textgrid 
comment and named as ordered integers from 1 until the total number of events.
boolean enkode_analysis
    positive fcut 100
    positive foss 500
boolean spectrum_analysis 1
	positive range 5000
	positive bins 116
endform
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
		if  'val1' > 'val2' and 'up' = 1 and 'f0' = 0
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
	bw='range'/'bins'
        nbs = Get number of bins
	repeat
		val1 = Get real value in bin: 'i'
		fi = Get frequency from bin number: 'i'
		i = 'i' + 1
                fact='bw' * 'step'
	        if 'fi' > 'fact'
		   
			res=('val1' + 'val')/'div' 
			fileappend 'defaultDirectory$'/spectrum 'res' 
			val = 'val1'
  			div=1
			step = 'step' + 1
                else
                	val ='val1' + 'val'
			div='div'+1
                endif
	until 'step' = 'bins'+1
endproc
# ---------------------------------
Read from file... 'soundfile$'
current_sound$ = selected$ ("Sound")
Read from file... 'textgrid$'
current_textgrid$ = selected$ ("TextGrid")
filedelete 'defaultDirectory$'/enkode
select TextGrid 'current_textgrid$'
n = Count intervals where: 1, "is not equal to", ""
    	for nn from 1 to n
	select Sound 'current_sound$'
	plus TextGrid 'current_textgrid$'
	Extract intervals where: 1, "no", "is equal to", "'nn'"
		duration = Get total duration
        	do ("To Spectrum...", "yes")
        	centroid = Get centre of gravity... 2
		if (centroid = undefined)
			centroid = 'fcut'/2
		endif
		Cepstral smoothing: 'foss'
# ---------------------------------
		if (spectrum_analysis = 1)
		call mk_spectrum
		fileappend 'defaultDirectory$'/spectrum 'newline$'
		endif
# ---------------------------------
		if (enkode_analysis = 1)
		call get_first_partial
		
		if (f0 = 0)
			f0 = 'fcut'/2
		endif
		select Spectrum 'current_sound$'_'nn'_1
		Remove
      	select Sound 'current_sound$'_'nn'_1
        nocheck To Cochleagram: 0.01, 0.1, 0.03, 0.03
	nocheck To Excitation (slice): 0
	loudness = nocheck Get loudness
        if (loudness = undefined)
                loudness = 1.6
		bass = 1.6
	select Sound 'current_sound$'_'nn'_1
	Remove
        else
	select Cochleagram 'current_sound$'_'nn'_1
	plus Excitation 'current_sound$'_'nn'_1
	Remove
	
	select Sound 'current_sound$'_'nn'_1
      	do ("Filter (stop Hann band)...", 'fcut', 0, 50)
      	select Sound 'current_sound$'_'nn'_1_band
	To Cochleagram: 0.01, 0.1, 0.03, 0.03
	To Excitation (slice): 0
	bass = Get loudness
      	appendFileLine("enkode", 'duration', " ", 'loudness', " ", 'centroid', " ", 'bass', " ", 'f0')
	endif
	select Spectrum 'current_sound$'_'nn'_1
      	plus Sound 'current_sound$'_'nn'_1
      	plus Sound 'current_sound$'_'nn'_1_band
        plus Cochleagram 'current_sound$'_'nn'_1_band
        plus Excitation 'current_sound$'_'nn'_1_band
      	Remove
	endif
	endfor
select all
Remove