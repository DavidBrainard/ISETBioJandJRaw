% ISETBioJandJLocalHookTemplate
%
% Template for setting preferences and other configuration things, for the
% ISETBioJandJ project.

% 04/09/22  NPC   Wrote it.

%% Define project
projectName = 'ISETBioJandJ';

%% Clear out old preferences
if (ispref(projectName))
    rmpref(projectName);
end

%% Specify project location
projectBaseDir = tbLocateProject(projectName);

%% Specificy generatedData dir location
computerInfo = GetComputerInfo;






