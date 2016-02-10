function AdaptorInfo = ioscan()
%
% created by WA, July, 2006
% Modified 2/1/07 (bug in digitalio assignments fixed) --WA
% Modified 1/4/08 (improved error handling) --WA

disp('<<< MonkeyLogic >>> Gathering I/O board info (running ioscan.m)...')
hwinfo = daqhwinfo;
fprintf('<<< MonkeyLogic >>> DAQ Driver Version: %s %s\n', daq.getVendors().FullName, daq.getVendors().DriverVersion);
fprintf('<<< MonkeyLogic >>> DAQ Toolbox Version: %s %s\n', hwinfo.ToolboxName, hwinfo.ToolboxVersion);

%insert an additional adapter
numFound = length(hwinfo.InstalledAdaptors);
hwinfo.InstalledAdaptors(numFound+1) = cellstr('USB (Universal Serial Bus)');

adaptors = hwinfo.InstalledAdaptors;

if ~iscell(adaptors),
    adaptors = {adaptors};
end
totalboards = 0;
AdaptorInfo(1:length(adaptors)) = struct;
for adaptornum = 1:length(adaptors),
    clear adapinfo
    try
        adapinfo = daqhwinfo(adaptors{adaptornum});
    catch
        adapinfo.InstalledBoardIds = '';
    end
    if isempty(adapinfo.InstalledBoardIds),
        totalboards = totalboards + 1;
        if strcmp(adaptors{adaptornum}, 'USB (Universal Serial Bus)')
            AdaptorInfo(totalboards).Name = sprintf('%s', adaptors{adaptornum});
            AdaptorInfo(totalboards).SubSystemsConstructors = {''};
            AdaptorInfo(totalboards).SubSystemsNames = {'DigitalInputStream'};
            AdaptorInfo(totalboards).AvailableChannels = {[1 2]};
            AdaptorInfo(totalboards).AvailablePorts = {[]};
            AdaptorInfo(totalboards).AvailableLines = {[]};
            AdaptorInfo(totalboards).SampleRate = 60;
            AdaptorInfo(totalboards).MaxSampleRate = 60;
            AdaptorInfo(totalboards).MinSampleRate = 60;
        else
            AdaptorInfo(totalboards).Name = sprintf('%s (Not Connected)', adaptors{adaptornum});
            AdaptorInfo(totalboards).SubSystemsConstructors = {''};
            AdaptorInfo(totalboards).SubSystemsNames = {''};
            AdaptorInfo(totalboards).AvailableChannels = {[]};
            AdaptorInfo(totalboards).AvailablePorts = {[]};
            AdaptorInfo(totalboards).AvailableLines = {[]};
            AdaptorInfo(totalboards).SampleRate = 0;
            AdaptorInfo(totalboards).MaxSampleRate = 0;
            AdaptorInfo(totalboards).MinSampleRate = 0;
        end
        
    else
        numboards = length(adapinfo.InstalledBoardIds);
        for bnum = 1:numboards,
            totalboards = totalboards + 1;
            AdaptorInfo(totalboards).Name = sprintf('%s: %s', adaptors{adaptornum}, adapinfo.BoardNames{bnum});
            allobconstructors = adapinfo.ObjectConstructorName(bnum, :);
            obconstructors = {};
            for csnum = 1:length(allobconstructors),
                if ~isempty(allobconstructors{csnum}),
                    obconstructors = cat(1, obconstructors, allobconstructors(csnum));
                end
            end
            cnt = 0;
            if ~isempty(obconstructors),
                for subsysnum = 1:length(obconstructors),
                    cname = obconstructors{subsysnum};
                    if ~isempty(cname),
                        cnt = cnt + 1;
                        AdaptorInfo(totalboards).SubSystemsConstructors{cnt} = cname;
                        sigch = eval(AdaptorInfo(totalboards).SubSystemsConstructors{cnt});
                        sigch_info = daqhwinfo(sigch);
                        AdaptorInfo(totalboards).SubSystemsNames{cnt} = sigch_info.SubsystemType;
                        if isfield(sigch_info, 'SingleEndedIDs'),
                            AdaptorInfo(totalboards).AvailableChannels{cnt} = sigch_info.SingleEndedIDs';
                            AdaptorInfo(totalboards).AvailablePorts{cnt} = [];
                        elseif isfield(sigch_info, 'ChannelIDs'),
                            AdaptorInfo(totalboards).AvailableChannels{cnt} = sigch_info.ChannelIDs';
                            AdaptorInfo(totalboards).AvailablePorts{cnt} = [];
                        elseif isfield(sigch_info, 'TotalChannels'),
                            AdaptorInfo(totalboards).AvailableChannels{cnt} = (1:sigch_info.TotalChannels)';
                            AdaptorInfo(totalboards).AvailablePorts{cnt} = [];
                        else %digital
                            AdaptorInfo(totalboards).AvailableChannels{cnt} = [];
                            port_info = sigch_info.Port;
                            AdaptorInfo(totalboards).AvailablePorts{cnt} = cat(2, port_info.ID);
                            AdaptorInfo(totalboards).AvailableLines{cnt} = {port_info.LineIDs};
                        end
                        try
                            AdaptorInfo(totalboards).MaxSampleRate(cnt) = sigch_info.MaxSampleRate;
                            AdaptorInfo(totalboards).MinSampleRate(cnt) = sigch_info.MinSampleRate;
                            AdaptorInfo(totalboards).SampleRate(cnt) = AdaptorInfo(bnum).MaxSampleRate(cnt);
                        catch
                            AdaptorInfo(totalboards).SampleRate(cnt) = NaN; %if digitalio
                            AdaptorInfo(totalboards).MaxSampleRate(cnt) = NaN;
                            AdaptorInfo(totalboards).MinSampleRate(cnt) = NaN;
                        end
                        delete(sigch);
                        clear sigch;
                    end
                end
            else
                AdaptorInfo(totalboards).Name = sprintf('%s (DAQ Device Not Supported)', adaptors{adaptornum});
                AdaptorInfo(totalboards).SubSystemsConstructors = {''};
                AdaptorInfo(totalboards).SubSystemsNames = {''};
                AdaptorInfo(totalboards).AvailableChannels = {[]};
                AdaptorInfo(totalboards).AvailablePorts = {[]};
                AdaptorInfo(totalboards).AvailableLines = {[]};
                AdaptorInfo(totalboards).SampleRate = 0;
                AdaptorInfo(totalboards).MaxSampleRate = 0;
                AdaptorInfo(totalboards).MinSampleRate = 0;
            end
        end
    end
end

fprintf('<<< MonkeyLogic >>> Found %i I/O adaptors:\n', length(adaptors));
for i = 1:length(adaptors),
	fprintf('... %i) %s\n', i, adaptors{i});
end
AdaptorInfo = AdaptorInfo(1:totalboards);

