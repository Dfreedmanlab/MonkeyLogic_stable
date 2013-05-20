function command = mlwebsummary(s, varargin)
%1 = initialize. inputs: (1, MLConfig, WebPageTemplate)
%2 = update stats/text. inputs: (2, TrialRecord, StatString)
%3 = update figure. inputs: (3, TrialRecord)
%4 = upload. inputs(4)
%
% Created by WA 7/22/08 -WA
% Modified 7/25/08 -WA (fixed graph for small trial numbers)
% Modified 7/26/08 -WA (fixed small bugs in two ML variables)

persistent H W F

if s == 1, %initialize
    mlftp(-1);
    MLConfig = varargin{1};
    H.WebPage = varargin{2};
    
    mlprefdirs = getpref('MonkeyLogic', 'Directories');
    F.MLDir = mlprefdirs.BaseDirectory;
    
    F.ActionFile = [MLConfig.ComputerName 'command.php'];
    F.PHP_File = [F.ActionFile];
    F.CommandFile = [MLConfig.ComputerName 'command.txt'];
    
    H.HTML_File = [MLConfig.ComputerName '.html'];
    H.BMP_File = [MLConfig.ComputerName '.bmp'];
    
    fn = fieldnames(MLConfig);
    for i = 1:length(fn),
        W.(['ML_' fn{i}]) = MLConfig.(fn{i});
    end
    W.ML_LastUpdate = datestr(now);
    W.ML_Status = 'Starting...';
    W.ML_TrialNumber = num2str(0);
    W.ML_ThisBlockTrialNumber = num2str(0);
    W.ML_OverAllCorrect = num2str(NaN);
    W.ML_ThisBlockCorrect = num2str(NaN);
    W.ML_HTML = H.WebPage;

    F.BatchFileName = [F.MLDir 'ml.ftp'];
    F.Server = MLConfig.Alerts.WebPage.Server;
    F.User = MLConfig.Alerts.WebPage.User;
    F.Pwd = MLConfig.Alerts.WebPage.Pwd;
    F.FTPdir = MLConfig.Alerts.WebPage.FTPdir;
        
    fid = fopen([F.MLDir F.PHP_File], 'w');
    fprintf(fid, '<?php\r\n');
    fprintf(fid, '$command = $_POST[''command''];\r\n');
    fprintf(fid, '$passcode = $_POST[''passcode''];\r\n');
    fprintf(fid, '$now = time();\r\n');
    fprintf(fid, '$fp=fopen("%s","w");\r\n', F.CommandFile);
    fprintf(fid, 'fwrite($fp,$command.''*'');\r\n');
    fprintf(fid, 'fwrite($fp,$passcode.''|'');\r\n');
    fprintf(fid, 'fwrite($fp,$now);\r\n');
    fprintf(fid, 'fclose($fp);\r\n');
    fprintf(fid, 'header("Location: {$_SERVER[''HTTP_REFERER'']}");\r\n');
    fprintf(fid, '?>\r\n');
    
    %{
    fprintf(fid, '<HTML>\r\n');
    fprintf(fid, '<HEAD>\r\n');
    fprintf(fid, '<meta HTTP-EQUIV="REFRESH" content="0; url=http://%s/%s/%s.html">\r\n', F.Server, F.FTPdir, MLConfig.ComputerName);
    fprintf(fid, '</HEAD>\r\n');
    fprintf(fid, '</HTML>\r\n');
    fprintf(fid, '<?PHP\r\n');
    fprintf(fid, '$command = $_POST[''command''];\r\n');
    fprintf(fid, '$passcode = $_POST[''passcode''];\r\n');

    fprintf(fid, 'exit();\r\n');
    fprintf(fid, '?>\r\n');
    %}
    fclose(fid);
    mlftp(F, [F.MLDir F.PHP_File]);
    
elseif s == 2, %update stats/text
    TrialRecord = varargin{1};
    W.ML_Status = varargin{2};
    if length(varargin) > 2,
        W.ML_RAMessage = varargin{3};
    else
        W.ML_RAMessage = ' ';
    end
    W.ML_TrialNumber = TrialRecord.CurrentTrialNumber;
    W.ML_TrialNumber = sprintf('%i', W.ML_TrialNumber);
    W.ML_ThisBlockTrialNumber = TrialRecord.CurrentTrialWithinBlock;
    W.ML_ThisBlockTrialNumber = sprintf('%i', W.ML_ThisBlockTrialNumber);
    W.ML_TotalCorrectTrials = sprintf('%i', sum(~TrialRecord.TrialErrors));
    if TrialRecord.RecentReset > TrialRecord.CurrentTrialNumber,
        W.ML_RecentCorrect = '--';
    else
        W.ML_RecentCorrect = 100*sum(~TrialRecord.TrialErrors(TrialRecord.RecentReset:end))/(TrialRecord.CurrentTrialNumber-TrialRecord.RecentReset+1);
        W.ML_RecentCorrect = sprintf('%2.1f', W.ML_RecentCorrect);
    end
    W.ML_OverAllCorrect = 100*sum(~TrialRecord.TrialErrors)/TrialRecord.CurrentTrialNumber;
    W.ML_OverAllCorrect = sprintf('%2.1f', W.ML_OverAllCorrect);
    W.ML_ThisBlockCorrect = 100*sum(~TrialRecord.TrialErrors(end-TrialRecord.CurrentTrialWithinBlock+1:end))/TrialRecord.CurrentTrialWithinBlock;
    W.ML_ThisBlockCorrect = sprintf('%2.1f', W.ML_ThisBlockCorrect);
    W.ML_LastUpdate = datestr(now);
    W.ML_CurrentCondition = num2str(TrialRecord.CurrentCondition);
    W.ML_CurrentBlock = num2str(TrialRecord.CurrentBlock);
    W.ML_BlockCount = num2str(TrialRecord.BlockCount(end));
    W.ML_BlocksCompleted = W.ML_BlockCount - 1;
    W.ML_MeanReactionTime = sprintf('%3.1f', mean(TrialRecord.ReactionTimes));
    W.ML_CommandEntry = sprintf('<table width="490" height="189" border="5" cellpadding="5"><tr><th height="175" scope="row"><center>Remote Command<br /><br /><span class="style1">%s</span><form id="form1" name="form1" method="post" action="%s"><label>Instruction: <input type="text" name="command" /></label><br /><br /><label>Authorization: <input name="passcode" type="password" /></label><br /><br /><input name="submit" type="submit" value="Submit" /></form></center></th></tr></table>', W.ML_RAMessage, F.ActionFile);
    n = 25;
    if TrialRecord.CurrentTrialNumber < n,
        n = TrialRecord.CurrentTrialNumber;
    end
    W.ML_RecentTrialErrorsAll = sprintf('%i', TrialRecord.TrialErrors(end-n+1:end));
    tc = TrialRecord.TrialErrors(TrialRecord.ConditionsPlayed == TrialRecord.CurrentCondition);
    if ~isempty(tc),
        if length(tc) < n,
            n = length(tc);
        end
        W.ML_RecentTrialErrorsThisCondition = sprintf('%i', tc(end-n+1:end));
    else
        W.ML_RecentTrialErrorsThisCondition = 'N/A';
    end
    fn = fieldnames(W);
    f_read = fopen(H.WebPage, 'r');
    f_write = fopen([F.MLDir H.HTML_File], 'w');
    while ~feof(f_read),
        txt = fgetl(f_read);
        for i = 1:length(fn),
            thisf = fn{i};
            if strfind(txt, thisf),
                txt = strrep(txt, fn{i}, W.(thisf));
            end
        end
        fprintf(f_write, '%s\r', txt);
    end
    fclose(f_read);
    fclose(f_write);
elseif s == 3, %update figure
    TrialRecord = varargin{1};
    
    f = findobj('tag', 'webfig1');
    if isempty(f),
        f = figure;
        set(f, 'position', [100 200 600 300], 'paperpositionmode', 'auto', 'tag', 'webfig1');
    else
        set(f, 'visible', 'on');
        cla;
    end

    te = TrialRecord.TrialErrors;
    lte = length(te);
    if lte < 2,
        h = text(.5, .5, 'First Update Pending...');
        set(h, 'horizontalalignment', 'center', 'fontsize', 14);
        drawnow;
        saveas(f, [F.MLDir H.BMP_File], 'bmp');
        drawnow;
        set(f, 'visible', 'off');
        drawnow;
        return
    end
    
    bnum = TrialRecord.BlocksPlayed;
    bswitch = find(diff(bnum));
    set(gca, 'color', (get(gcf, 'color')), 'xlim', [1 lte], 'ylim', [0 1], 'position', [.1 .15 .85 .8], 'box', 'on', 'tag', 'behaviorovertime');
    hold on;

    colororder = [0 1 0; 0 1 1; 1 1 0; 0 0 1; 0.5 0.5 0.5; 1 0 1; 1 0 0; .3 .7 .5; .7 .2 .5; .5 .5 1; .75 .75 .5];
    corder(1, 1:7, 1:3) = colororder(1:7, 1:3);

    h1 = xlabel('Trial Number');
    h2 = ylabel('Fraction Correct');
    set([h1 h2], 'fontsize', 14);

    smoothwin = 10;
    if length(te) < 5*smoothwin,
        x = 1:length(te);
        for tenumber = 0:7,
            y = zeros(size(x));
            y(te == tenumber) = 1;
            h = bar(x, y, 1);
            set(h, 'facecolor', colororder(tenumber+1, :), 'edgecolor', [1 1 1]);
            set(gca, 'xlim', [0.5 length(te)+0.5]);
        end
        set(gca, 'xlim', [0.5 length(te)+0.5]);
    else
        yarray1 = zeros(lte, 8);
        for i = 0:6,
            r = smooth(double(te' == i), smoothwin, 'gauss');
            yarray1(1:lte, i+2) = yarray1(1:lte, i+1) + r;
        end
        xarray1 = (1:lte)';
        xarray1 = repmat(xarray1, 1, 8);

        xarray2 = flipud(xarray1);
        yarray2 = flipud(yarray1);

        x = cat(1, xarray1(:, 1:7), xarray2(:, 2:8));
        y = cat(1, yarray1(:, 1:7), yarray2(:, 2:8));

        warning off
        h = patch(x, y, corder);
        set(h, 'tag', 'behaviorpatch', 'buttondownfcn', 'behaviorsummary');
        hline(1) = line([0 lte], [0.5 0.5]);
        set(hline(1), 'color', [0.7 0.7 0.7], 'linewidth', 2);
        hline(2) = line([0 lte], [0.25 0.25]);
        hline(3) = line([0 lte], [0.75 0.75]);
        set(hline([2 3]), 'color', [0.7 0.7 0.7], 'linewidth', 1);
        h = zeros(length(bswitch), 1);
        ht = h;
        texty = 0.05;
        for i = 1:length(bswitch),
            x1 = bswitch(i);
            h(i) = line([x1 x1], [0 1]);
            if i > 1,
                x2 = bswitch(i-1);
            else
                x2 = 0;
            end
            xm = (x1 + x2)/2;
            ht(i) = text(xm, texty, num2str(TrialRecord.BlockOrder(i)));
        end
        if ~isempty(h),
            xm = (bswitch(i) + TrialRecord.CurrentTrialNumber)/2;
            ht(i+1) = text(xm, texty, num2str(TrialRecord.BlockOrder(i+1)));
            set(h, 'color', [1 1 1], 'linewidth', 2);
        else
            xm = TrialRecord.CurrentTrialNumber/2;
            ht = text(xm, texty, num2str(TrialRecord.BlockOrder));
        end
        set(ht, 'horizontalalignment', 'center', 'color', [1 1 1], 'fontweight', 'bold', 'fontsize', 14);
    end
    warning on
    
    drawnow;
    saveas(f, [F.MLDir H.BMP_File], 'bmp');
    drawnow;
    set(f, 'visible', 'off');
    drawnow;

elseif s == 4, %ftp access
    include_pic = 0;
    get_command_only = 0;
    if ~isempty(varargin),
        if strcmpi(varargin{1}, 'UpdateFigure'),
            include_pic = 1;
        elseif strcmpi(varargin{1}, 'GetCommandOnly'),
            get_command_only = 1;
        end
    end
    if include_pic,
        mlftp(F, [F.MLDir H.HTML_File], [F.MLDir H.BMP_File]);
    elseif get_command_only,
        mlftp(F);
    else
        mlftp(F, [F.MLDir H.HTML_File]);
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mlftp(F, varargin)
persistent pid

if isnumeric(F) && F==-1,
    pid=0;
    return
end

files = {};
if ~isempty(varargin),
    files = cell(1, length(varargin));
    for i = 1:length(varargin),
        files{i} = strrep(varargin{i}, '\', '\\');
    end
end

fid = fopen(F.BatchFileName, 'w');
fprintf(fid, 'open %s\r\n', F.Server);
fprintf(fid, '%s\r\n', F.User);
fprintf(fid, '%s\r\n', F.Pwd);
fprintf(fid, 'literal pasv\r\n');
fprintf(fid, 'cd %s\r\n', F.FTPdir);
for i = 1:length(files),
    f = files{i};
    [pname fname ext] = fileparts(f);
    ispic = 0;
    if strcmpi(ext, {'.bmp' '.jpg' '.jpeg' '.tiff' '.bmp' '.gif' '.png'}),
        fprintf(fid, 'bin\r\n');
        ispic = 1;
    end
    fprintf(fid, 'put %s\r\n', f);
    if ispic,
        fprintf(fid, 'ascii\r\n');
    end
end
fprintf(fid, sprintf('get %s %s\r\n', F.CommandFile, strrep([F.MLDir F.CommandFile], '\', '\\')));
fprintf(fid, 'disconnect\r\n');
fprintf(fid, 'quit\r\n');
fclose(fid);

pid = system([F.MLDir 'killlaststart.vbs ' num2str(pid) ' ftp -v -s:' F.BatchFileName]);
% shellcommand = ['!' mldir 'hstart.vbs ftp -v -s:' F.BatchFileName];
% eval(shellcommand);
% fid2 = fopen(F.CommandFile, 'r+');
% if ~feof(fid2),
%     command = fgetl(fid2);
% end
% fclose(fid2);

