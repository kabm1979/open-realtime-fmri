function [cburt]=cburt_benchmark(cburt)

if (~exist('cburt','var'))
    load cburt
end;

recursive_dump(cburt.benchmarking,'root','');

end


function recursive_dump(bench,name,indent)
indentchar='  ';
fprintf('%s%s\t',indent,name);
try
    dur=etime(bench.stop,bench.start);
    fprintf('%f',dur);
catch
end;
fprintf('\n');

if (isstruct(bench))
    fn=fieldnames(bench);
    fn(strcmp(fn,'start') | strcmp(fn,'stop'))=[];
    for i=1:length(fn)
        if (length(bench.(fn{i}))>1)
            for j=1:length(bench.(fn{i}))
                recursive_dump(bench.(fn{i})(j),sprintf('%s %d',fn{i},j),[indent indentchar]);
            end;
        else
            recursive_dump(bench.(fn{i}),fn{i},[indent indentchar]);
        end;
    end;
end;
end

