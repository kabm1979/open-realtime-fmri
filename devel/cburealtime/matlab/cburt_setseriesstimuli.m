function [cburt]=cburt_setseriesstimuli(cburt,seriesnum)

if (cburt.model.runspecificstimuli)
    cburt.model.numstimulilistsused=cburt.model.numstimulilistsused+1;
    cburt.model.series(seriesnum).stimuli=cburt.model.stimuli(:,cburt.model.numstimulilistsused);
else
    cburt.model.series(seriesnum).stimuli=cburt.model.stimuli;
end;