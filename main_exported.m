classdef main_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        FileMenu                        matlab.ui.container.Menu
        OpenMenu                        matlab.ui.container.Menu
        ExitMenu                        matlab.ui.container.Menu
        HelpMenu                        matlab.ui.container.Menu
        AboutMenu                       matlab.ui.container.Menu
        RESULTSPanel                    matlab.ui.container.Panel
        SaveMarkedBoardMapButton        matlab.ui.control.Button
        SaveBoardMapButton              matlab.ui.control.Button
        NeutralTerritoryEditField       matlab.ui.control.EditField
        NeutralTerritoryEditFieldLabel  matlab.ui.control.Label
        WhiteTerritoryEditField         matlab.ui.control.EditField
        WhiteTerritoryEditFieldLabel    matlab.ui.control.Label
        BlackTerritoryEditField         matlab.ui.control.EditField
        BlackTerritoryEditFieldLabel    matlab.ui.control.Label
        WhiteStonesEditField            matlab.ui.control.EditField
        WhiteStonesEditFieldLabel       matlab.ui.control.Label
        BlackStonesEditField            matlab.ui.control.EditField
        BlackStonesEditFieldLabel       matlab.ui.control.Label
        INPUTPanel                      matlab.ui.container.Panel
        LoadButton                      matlab.ui.control.Button
        ImageAxes                       matlab.ui.control.UIAxes
        CONTROLSPanel                   matlab.ui.container.Panel
        REditField                      matlab.ui.control.NumericEditField
        REditFieldLabel                 matlab.ui.control.Label
        startYEditField                 matlab.ui.control.NumericEditField
        startYEditFieldLabel            matlab.ui.control.Label
        startXEditField                 matlab.ui.control.NumericEditField
        startXEditFieldLabel            matlab.ui.control.Label
        RecalculateButton               matlab.ui.control.Button
        WhiteDetectionEditField         matlab.ui.control.NumericEditField
        WhiteDetectionEditFieldLabel    matlab.ui.control.Label
        BlackDetectionEditField         matlab.ui.control.NumericEditField
        BlackDetectionEditFieldLabel    matlab.ui.control.Label
        RmaxEditField                   matlab.ui.control.NumericEditField
        RmaxEditFieldLabel              matlab.ui.control.Label
        RminEditField                   matlab.ui.control.NumericEditField
        RminEditFieldLabel              matlab.ui.control.Label
    end

    
    properties (Access = private)
        Property % Description
        % save original image file in currentInput
        % save processed (grayscaled, etc) image in processedInput
        % save input image original file type in inputFileType
        % save processed edge image in currentEdge
        % save current processed output in currentOutput
        % save last saved mask size in maskSize
        currentInput = [];
        enhancedInput = [];
        currentOutput = [];
        inputFileType = [];
        averageRadius = 1;
        boardArray = zeros(19);
        boardArrayMarked = zeros(19);
    end
    
    methods (Access = private)       
        function enhanceimage(app)
            shadow_lab = rgb2lab(app.currentInput);
            max_luminosity = 100;
            L = shadow_lab(:,:,1)/max_luminosity;
            %shadow_adapthisteq = shadow_lab;
            %shadow_adapthisteq(:,:,1) = adapthisteq(L)*max_luminosity;
            %app.enhancedInput = lab2rgb(shadow_adapthisteq);
            shadow_histeq = shadow_lab;
            shadow_histeq(:,:,1) = histeq(L)*max_luminosity;
            app.enhancedInput = lab2rgb(shadow_histeq);
        end

        function updateimage(app)
            im = app.currentInput;
            imagesc(app.ImageAxes, im);

            % Update automatically calculated radius
            boardSize = size(app.currentInput,1);
            Rmin = round(boardSize/19/4);
            Rmax = round((boardSize/19/2)*1.5);
            app.RminEditField.Value = Rmin;
            app.RmaxEditField.Value = Rmax;

            % Update output
            enhanceimage(app);
            updateoutput(app);
        end            
        
        function updateoutput(app, startX, startY, radius)
            % Get all light and dark circles from image
            output = app.enhancedInput;
            Rmin = app.RminEditField.Value;
            Rmax = app.RmaxEditField.Value;
            [centersBright, radiiBright] = imfindcircles(output,[Rmin Rmax],'ObjectPolarity','bright','Sensitivity', app.WhiteDetectionEditField.Value);
            [centersDark, radiiDark] = imfindcircles(output,[Rmin Rmax],'ObjectPolarity','dark','Sensitivity', app.BlackDetectionEditField.Value);
            app.averageRadius = mean(cat(1,radiiBright,radiiDark));

            % Determine top left point from min x and y of stones
            if nargin < 2
                xBright = centersBright(:,1);
                yBright = centersBright(:,2);
                xDark = centersDark(:,1);
                yDark = centersDark(:,2);
                startX = min(min(xBright), min(xDark));
                startY = min(min(yBright), min(yDark));
                app.startXEditField.Value = startX;
                app.startYEditField.Value = startY;
                app.REditField.Value = app.averageRadius;
                radius = app.averageRadius;
            end
            curY = startY;

            % Start iteration to create board
            % Assume board is 19 x 19
            for i = 1:19
                curX = startX;
                for j = 1:19
                    if(isPointInCircle(curX, curY, radiiBright, centersBright))
                        % Point is a white stone
                        app.boardArray(i,j) = 2;
                    elseif(isPointInCircle(curX, curY, radiiDark, centersDark))
                        % Point is a black stone
                        app.boardArray(i,j) = 1;
                    else
                        % Point is a a territory
                        app.boardArray(i,j) = 0;
                    end
                    curX = curX + (radius*2.1);
                end
                curY = curY + (radius*2.1);
            end
            
            % Create marked board map
            app.boardArrayMarked = fillBoard(app.boardArray);
            app.BlackTerritoryEditField.Value = int2str(sum(app.boardArrayMarked(:) == 3));
            app.WhiteTerritoryEditField.Value = int2str(sum(app.boardArrayMarked(:) == 4));
            app.NeutralTerritoryEditField.Value = int2str(sum(app.boardArrayMarked(:) == 0));

            % Update Information Fields
            % app.BlackStonesEditField.Value = int2str(length(centersDark));
            % app.WhiteStonesEditField.Value = int2str(length(centersBright));
            app.BlackStonesEditField.Value = int2str(sum(app.boardArray(:) == 1)) + " (" + int2str(length(centersDark)) + ")";
            app.WhiteStonesEditField.Value = int2str(sum(app.boardArray(:) == 2)) + " (" + int2str(length(centersBright)) + ")";
           
            % Display result
            imshow(app.currentInput,'Parent',app.ImageAxes);
            viscircles(app.ImageAxes, centersBright, radiiBright,'Color','b');
            viscircles(app.ImageAxes, centersDark, radiiDark,'LineStyle','--');
            
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Configure image axes
            app.ImageAxes.Visible = 'off';
            app.ImageAxes.Colormap = gray(256);
            axis(app.ImageAxes, 'image');

            % Update the image
            app.currentInput = imread('default-resize.png');
            updateimage(app);
        end

        % Callback function: LoadButton, OpenMenu
        function LoadButtonPushed(app, event)
               
            % Display uigetfile dialog
            filterspec = {'*.jpg;*.png','All Image Files'};
            fig = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);
            [f, p] = uigetfile(filterspec);
            delete(fig);
            
            % Make sure user didn't cancel uigetfile dialog
            if (ischar(p))
               fname = [p f];
               try
                   [~,~,ext] = fileparts(fname);
                   app.inputFileType = ext;
                   imsize = size(imread(fname));
                   if (length(imsize) == 2)
                       [indexedImage, map] = imread(fname);
                       rgbImage = ind2rgb(indexedImage, map);
                       app.currentInput = rgbImage;
                   else
                       im = imread(fname);
                       app.currentInput = im;
                   end
                   updateimage(app);

               catch ME
                   % If problem reading image, display error message
                   uialert(app.UIFigure, ME.message, 'Image Error');
                   return;
               end
               figure(app.UIFigure);
               
            end
        end

        % Button pushed function: RecalculateButton
        function RecalculateButtonPushed(app, event)
            updateoutput(app, app.startXEditField.Value, app.startYEditField.Value, app.REditField.Value);
        end

        % Menu selected function: ExitMenu
        function ExitMenuSelected(app, event)
            app.delete;
        end

        % Button pushed function: SaveBoardMapButton
        function SaveBoardMapButtonPushed(app, event)
            % Display uigetfile dialog
            filterspec = {'*.txt','Text File'};
            defaultName = ['output' '.txt'];
            fig = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);
            [f, p] = uiputfile(filterspec,'Save Board As Text',defaultName);
            delete(fig);
            
            % Make sure user didn't cancel uigetfile dialog
            if (ischar(p))
               fname = [p f];
               try
                   writematrix(app.boardArray,fname)
               catch ME
                   % If problem reading image, display error message
                   uialert(app.UIFigure, ME.message, 'Save Error');
                   return;
               end
               
            end
        end

        % Button pushed function: SaveMarkedBoardMapButton
        function SaveMarkedBoardMapButtonPushed(app, event)
            % Display uigetfile dialog
            filterspec = {'*.txt','Text File'};
            defaultName = ['output-marked' '.txt'];
            fig = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);
            [f, p] = uiputfile(filterspec,'Save Board As Text',defaultName);
            delete(fig);
            
            % Make sure user didn't cancel uigetfile dialog
            if (ischar(p))
               fname = [p f];
               try
                   writematrix(app.boardArrayMarked,fname)
               catch ME
                   % If problem reading image, display error message
                   uialert(app.UIFigure, ME.message, 'Save Error');
                   return;
               end
               
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 827 477];
            app.UIFigure.Name = 'Go Score Counter';
            app.UIFigure.Scrollable = 'on';

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create OpenMenu
            app.OpenMenu = uimenu(app.FileMenu);
            app.OpenMenu.MenuSelectedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.OpenMenu.Text = 'Open...';

            % Create ExitMenu
            app.ExitMenu = uimenu(app.FileMenu);
            app.ExitMenu.MenuSelectedFcn = createCallbackFcn(app, @ExitMenuSelected, true);
            app.ExitMenu.Text = 'Exit';

            % Create HelpMenu
            app.HelpMenu = uimenu(app.UIFigure);
            app.HelpMenu.Text = 'Help';

            % Create AboutMenu
            app.AboutMenu = uimenu(app.HelpMenu);
            app.AboutMenu.Text = 'About';

            % Create CONTROLSPanel
            app.CONTROLSPanel = uipanel(app.UIFigure);
            app.CONTROLSPanel.Title = 'CONTROLS';
            app.CONTROLSPanel.Position = [328 28 483 172];

            % Create RminEditFieldLabel
            app.RminEditFieldLabel = uilabel(app.CONTROLSPanel);
            app.RminEditFieldLabel.Position = [16 114 33 22];
            app.RminEditFieldLabel.Text = 'Rmin';

            % Create RminEditField
            app.RminEditField = uieditfield(app.CONTROLSPanel, 'numeric');
            app.RminEditField.Limits = [1 Inf];
            app.RminEditField.RoundFractionalValues = 'on';
            app.RminEditField.Position = [64 114 69 22];
            app.RminEditField.Value = 1;

            % Create RmaxEditFieldLabel
            app.RmaxEditFieldLabel = uilabel(app.CONTROLSPanel);
            app.RmaxEditFieldLabel.Position = [16 83 36 22];
            app.RmaxEditFieldLabel.Text = 'Rmax';

            % Create RmaxEditField
            app.RmaxEditField = uieditfield(app.CONTROLSPanel, 'numeric');
            app.RmaxEditField.Limits = [1 Inf];
            app.RmaxEditField.RoundFractionalValues = 'on';
            app.RmaxEditField.Position = [64 83 69 22];
            app.RmaxEditField.Value = 1;

            % Create BlackDetectionEditFieldLabel
            app.BlackDetectionEditFieldLabel = uilabel(app.CONTROLSPanel);
            app.BlackDetectionEditFieldLabel.Position = [160 114 88 22];
            app.BlackDetectionEditFieldLabel.Text = 'Black Detection';

            % Create BlackDetectionEditField
            app.BlackDetectionEditField = uieditfield(app.CONTROLSPanel, 'numeric');
            app.BlackDetectionEditField.Limits = [0 1];
            app.BlackDetectionEditField.Position = [270 114 49 22];
            app.BlackDetectionEditField.Value = 0.9;

            % Create WhiteDetectionEditFieldLabel
            app.WhiteDetectionEditFieldLabel = uilabel(app.CONTROLSPanel);
            app.WhiteDetectionEditFieldLabel.Position = [159 83 90 22];
            app.WhiteDetectionEditFieldLabel.Text = 'White Detection';

            % Create WhiteDetectionEditField
            app.WhiteDetectionEditField = uieditfield(app.CONTROLSPanel, 'numeric');
            app.WhiteDetectionEditField.Limits = [0 1];
            app.WhiteDetectionEditField.Position = [269 83 49 22];
            app.WhiteDetectionEditField.Value = 0.85;

            % Create RecalculateButton
            app.RecalculateButton = uibutton(app.CONTROLSPanel, 'push');
            app.RecalculateButton.ButtonPushedFcn = createCallbackFcn(app, @RecalculateButtonPushed, true);
            app.RecalculateButton.Position = [15 13 451 26];
            app.RecalculateButton.Text = 'Recalculate';

            % Create startXEditFieldLabel
            app.startXEditFieldLabel = uilabel(app.CONTROLSPanel);
            app.startXEditFieldLabel.Position = [337 114 36 22];
            app.startXEditFieldLabel.Text = 'startX';

            % Create startXEditField
            app.startXEditField = uieditfield(app.CONTROLSPanel, 'numeric');
            app.startXEditField.Limits = [0 Inf];
            app.startXEditField.Position = [386 114 80 22];

            % Create startYEditFieldLabel
            app.startYEditFieldLabel = uilabel(app.CONTROLSPanel);
            app.startYEditFieldLabel.Position = [337 83 36 22];
            app.startYEditFieldLabel.Text = 'startY';

            % Create startYEditField
            app.startYEditField = uieditfield(app.CONTROLSPanel, 'numeric');
            app.startYEditField.Limits = [0 Inf];
            app.startYEditField.Position = [386 83 80 22];

            % Create REditFieldLabel
            app.REditFieldLabel = uilabel(app.CONTROLSPanel);
            app.REditFieldLabel.Position = [16 48 25 22];
            app.REditFieldLabel.Text = 'R';

            % Create REditField
            app.REditField = uieditfield(app.CONTROLSPanel, 'numeric');
            app.REditField.Limits = [1 Inf];
            app.REditField.Position = [64 48 402 22];
            app.REditField.Value = 1;

            % Create INPUTPanel
            app.INPUTPanel = uipanel(app.UIFigure);
            app.INPUTPanel.Title = 'INPUT';
            app.INPUTPanel.Position = [21 28 292 432];

            % Create ImageAxes
            app.ImageAxes = uiaxes(app.INPUTPanel);
            app.ImageAxes.XTick = [];
            app.ImageAxes.XTickLabelRotation = 0;
            app.ImageAxes.XTickLabel = {'[ ]'};
            app.ImageAxes.YTick = [];
            app.ImageAxes.YTickLabelRotation = 0;
            app.ImageAxes.ZTickLabelRotation = 0;
            app.ImageAxes.Position = [23 139 243 247];

            % Create LoadButton
            app.LoadButton = uibutton(app.INPUTPanel, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Position = [23 22 243 40];
            app.LoadButton.Text = 'Load Custom Image';

            % Create RESULTSPanel
            app.RESULTSPanel = uipanel(app.UIFigure);
            app.RESULTSPanel.Title = 'RESULTS';
            app.RESULTSPanel.Position = [328 217 481 243];

            % Create BlackStonesEditFieldLabel
            app.BlackStonesEditFieldLabel = uilabel(app.RESULTSPanel);
            app.BlackStonesEditFieldLabel.Position = [17 187 75 22];
            app.BlackStonesEditFieldLabel.Text = 'Black Stones';

            % Create BlackStonesEditField
            app.BlackStonesEditField = uieditfield(app.RESULTSPanel, 'text');
            app.BlackStonesEditField.Editable = 'off';
            app.BlackStonesEditField.Position = [197 187 270 22];

            % Create WhiteStonesEditFieldLabel
            app.WhiteStonesEditFieldLabel = uilabel(app.RESULTSPanel);
            app.WhiteStonesEditFieldLabel.Position = [17 154 76 22];
            app.WhiteStonesEditFieldLabel.Text = 'White Stones';

            % Create WhiteStonesEditField
            app.WhiteStonesEditField = uieditfield(app.RESULTSPanel, 'text');
            app.WhiteStonesEditField.Editable = 'off';
            app.WhiteStonesEditField.Position = [197 154 270 22];

            % Create BlackTerritoryEditFieldLabel
            app.BlackTerritoryEditFieldLabel = uilabel(app.RESULTSPanel);
            app.BlackTerritoryEditFieldLabel.Position = [17 121 81 22];
            app.BlackTerritoryEditFieldLabel.Text = 'Black Territory';

            % Create BlackTerritoryEditField
            app.BlackTerritoryEditField = uieditfield(app.RESULTSPanel, 'text');
            app.BlackTerritoryEditField.Editable = 'off';
            app.BlackTerritoryEditField.Position = [197 121 270 22];

            % Create WhiteTerritoryEditFieldLabel
            app.WhiteTerritoryEditFieldLabel = uilabel(app.RESULTSPanel);
            app.WhiteTerritoryEditFieldLabel.Position = [17 88 82 22];
            app.WhiteTerritoryEditFieldLabel.Text = 'White Territory';

            % Create WhiteTerritoryEditField
            app.WhiteTerritoryEditField = uieditfield(app.RESULTSPanel, 'text');
            app.WhiteTerritoryEditField.Editable = 'off';
            app.WhiteTerritoryEditField.Position = [197 88 270 22];

            % Create NeutralTerritoryEditFieldLabel
            app.NeutralTerritoryEditFieldLabel = uilabel(app.RESULTSPanel);
            app.NeutralTerritoryEditFieldLabel.Position = [17 55 90 22];
            app.NeutralTerritoryEditFieldLabel.Text = 'Neutral Territory';

            % Create NeutralTerritoryEditField
            app.NeutralTerritoryEditField = uieditfield(app.RESULTSPanel, 'text');
            app.NeutralTerritoryEditField.Editable = 'off';
            app.NeutralTerritoryEditField.Position = [197 55 270 22];

            % Create SaveBoardMapButton
            app.SaveBoardMapButton = uibutton(app.RESULTSPanel, 'push');
            app.SaveBoardMapButton.ButtonPushedFcn = createCallbackFcn(app, @SaveBoardMapButtonPushed, true);
            app.SaveBoardMapButton.Position = [18 16 206 23];
            app.SaveBoardMapButton.Text = 'Save Board Map';

            % Create SaveMarkedBoardMapButton
            app.SaveMarkedBoardMapButton = uibutton(app.RESULTSPanel, 'push');
            app.SaveMarkedBoardMapButton.ButtonPushedFcn = createCallbackFcn(app, @SaveMarkedBoardMapButtonPushed, true);
            app.SaveMarkedBoardMapButton.Position = [261 16 206 23];
            app.SaveMarkedBoardMapButton.Text = 'Save Marked Board Map';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = main_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end