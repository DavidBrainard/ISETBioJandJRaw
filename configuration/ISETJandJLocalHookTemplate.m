% ISETJandJLocalHookTemplate
%
% Template for setting preferences and other configuration things, for the
% ISETJandJ project.

% 10/23/18  NPC   Wrote it.

%% Define project
projectName = 'ISETJandJ';

%% Clear out old preferences
if (ispref(projectName))
    rmpref(projectName);
end

%% Specify project location
projectBaseDir = tbLocateProject('ISETJandJ');

%% Specificy generatedData dir location
computerInfo = GetComputerInfo;






