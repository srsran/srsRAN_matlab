%srsDiagnosticsOutputPlugin - Plugin to show diagnostics to an output stream.
%   The srsDiagnosticsOutputPlugin is a simple customization of MATLAB's
%   DiagnosticsOutputPlugin that removes diagnostics due to failed assumptions.
%
%   The srsDiagnosticsOutputPlugin enables configuration of a TestRunner to
%   show diagnostics to an output stream. The plugin can be configured to
%   specify the output stream, and the level of detail for displaying the runner
%   events. By default, srsDiagnosticsOutputPlugin uses the ToStandardOutput stream,
%   and only includes logged diagnostics at level Verbosity.Terse.
%
%   DiagnosticsOutputPlugin properties:
%       LoggingLevel  - Maximum verbosity level at which logged diagnostics are included
%       OutputDetail  - Verbosity level that defines amount of displayed information
%
%   DiagnosticsOutputPlugin methods:
%       srsDiagnosticsOutputPlugin  - Class constructor
%
%   See also matlab.unittest.plugins.DiagnosticsOutputPlugin

%   Copyright 2021-2025 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

classdef srsDiagnosticsOutputPlugin < matlab.unittest.plugins.DiagnosticsOutputPlugin
    methods
        function plugin = srsDiagnosticsOutputPlugin(stream, namedargs)
        %srsDiagnosticsOutputPlugin - Class constructor
        %   The constructor, in all the following versions, simply calls the
        %   corresponding matlab.unittest.plugins.DiagnosticsOutputPlugin constructor
        %   with the extra name-value arguments
        %   - 'ExcludingFailureDiagnostics', false
        %   - 'IncludingPassingDiagnostics', false
        %
        %   PLUGIN = srsDiagnosticsOutputPlugin creates an srsDiagnosticsOutputPlugin
        %   instance and returns it in PLUGIN. This plugin can be added to a
        %   TestRunner instance to show failure diagnostics and logged diagnostics
        %   that are logged at level Verbosity.Terse.
        %
        %   PLUGIN = srsDiagnosticsOutputPlugin(STREAM) creates an
        %   srsDiagnosticsOutputPlugin and redirects the text produced to the
        %   OutputStream STREAM. If STREAM is not supplied, a ToStandardOutput
        %   stream is used.
        %
        %   PLUGIN = srsDiagnosticsOutputPlugin(..., 'LoggingLevel', LOGGINGLEVEL)
        %   creates a srsDiagnosticsOutputPlugin that includes logged diagnostics that
        %   are logged at or below LOGGINGLEVEL. LOGGINGLEVEL is specified as a
        %   numeric value (0, 1, 2, 3, or 4), a matlab.unittest.Verbosity
        %   enumeration member, or a string or character vector corresponding to
        %   the name of a matlab.unittest.Verbosity enumeration member. To exclude
        %   logged diagnostics, specify LOGGINGLEVEL as Verbosity.None. By default,
        %   LOGGINGLEVEL is Verbosity.Terse.
        %
        %   PLUGIN = DiagnosticsOutputPlugin(..., 'OutputDetail', OUTPUTDETAIL)
        %   creates a DiagnosticsOutputPlugin that displays events with the amount
        %   of output detail specified by OUTPUTDETAIL. OUTPUTDETAIL is specified
        %   as a numeric value (0, 1, 2, 3, or 4), a matlab.unittest.Verbosity
        %   enumeration member, or a string or character vector corresponding to
        %   the name of a matlab.unittest.Verbosity enumeration member. By default,
        %   events are displayed at the Verbosity.Detailed level.
        %
        %   Example:
        %       import matlab.unittest.TestRunner;
        %       import matlab.unittest.TestSuite;
        %       import srsTest.plugins.DiagnosticsOutputPlugin;
        %       import matlab.unittest.Verbosity;
        %
        %       % Create a TestSuite array and create a TestRunner with no plugins
        %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
        %       runner = TestRunner.withNoPlugins();
        %
        %       % Create an instance of srsDiagnosticsOutputPlugin with a terse output detail level
        %       plugin = srsDiagnosticsOutputPlugin('OutputDetail',Verbosity.Terse);
        %
        %       % Add the plugin to the TestRunner and run the suite
        %       runner.addPlugin(plugin);
        %       result = runner.run(suite)

            arguments
                stream = matlab.automation.streams.ToStandardOutput
                namedargs.LoggingLevel (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Terse;
                namedargs.OutputDetail (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Detailed;
            end

            plugin@matlab.unittest.plugins.DiagnosticsOutputPlugin(stream, ...
                    ExcludingFailureDiagnostics=false, ...
                    IncludingPassingDiagnostics=false, ...
                    LoggingLevel=namedargs.LoggingLevel, ...
                    OutputDetail=namedargs.OutputDetail);
        end
    end

    methods (Hidden, Access=protected)
        function runTestSuite(plugin, pluginData)
        %Overload of DiagnosticsOutputPlugin.runTestSuite that discards "AssumptionFailed"
        %   events.

            import matlab.unittest.internal.plugins.getFailureSummaryTableText;
            plugin.LinePrinter = plugin.createLinePrinter();
            plugin.EventRecordFormatter = plugin.createEventRecordFormatter();
            plugin.EventRecordProcessor = plugin.createEventRecordProcessor();

            % Remove "AssumptionFailed" events from the diagnostics.
            plugin.EventRecordProcessor.TestCaseEvents ...
                    = setdiff(plugin.EventRecordProcessor.TestCaseEvents, "AssumptionFailed");

            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);

            if ~plugin.ExcludeFailureDiagnostics && plugin.OutputDetail > 1
                % Print summary of failures only.
                txt = getFailureSummaryTableText(pluginData.TestResult([pluginData.TestResult.Failed]'));
                if strlength(txt) > 0
                    plugin.LinePrinter.printLine(txt);
                end
            end
        end
    end % of methods (Hidden, Access=protected)

    % Private methods aren't accessible from child classes - copy-pasting the
    % original DiagnosticsOutputPlugin methods.
    methods(Access=private)
        function printer = createLinePrinter(plugin)
            import matlab.unittest.internal.plugins.LinePrinter;
            printer = LinePrinter(plugin.OutputStream);
        end

        function formatter = createEventRecordFormatter(plugin)
            import matlab.unittest.internal.plugins.StandardEventRecordFormatter;
            formatter = StandardEventRecordFormatter();
            formatter.AddDeliminatorsToExceptionEventReport = true;
            formatter.AddDeliminatorsToQualificationEventReport = true;
            formatter.UseAssumptionFailedEventMiniReport = true;
            formatter.ReportVerbosity = plugin.OutputDetail;
        end

        function processor = createEventRecordProcessor(plugin)
            import matlab.unittest.internal.plugins.EventRecordProcessor;
            import matlab.unittest.Verbosity;

            pluginWeakRef = matlab.lang.WeakReference(plugin);
            processor = EventRecordProcessor(@(eventRecord) pluginWeakRef.Handle.processEventRecord(eventRecord));
            if plugin.ExcludeFailureDiagnostics
                processor.removeFailureEvents();
            end
            if plugin.IncludePassingDiagnostics
                processor.addPassingEvents();
            end
            processor.LoggingLevel = plugin.LoggingLevel;
            processor.OutputDetail = plugin.OutputDetail;
        end

        function processEventRecord(plugin,eventRecord)
            reportStr = eventRecord.getFormattedReport(plugin.EventRecordFormatter);
            plugin.LinePrinter.printFormatted(appendNewlineIfNonempty(prependNewlineIfNonempty(reportStr)));
        end
    end
end % of classdef srsDiagnosticOutputPlugin < matlab.unittest.plugins.DiagnosticsOutputPlugin
