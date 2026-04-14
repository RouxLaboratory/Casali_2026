This README is a short introduction to the analytical pipeline used in the paper "Respiratory pauses highlight sleep architecture in mice" - Casali et al., 2026, Nature Communications.

For technical info please contact 
Dr. Giulio Casali (giulio.casali.pro@gmail.com)
Tim Gervois (tim.gervois@u-bordeaux.fr)
Dr. Nicolas Chenouard (nicolas.chenouard@gmail.com /  nicolas.chenouard@inserm.fr)
Dr. Lisa Roux (lisa.roux@u-bordeaux.fr )

These shared scripts permit to:
(1) study respiration and specifically pauses embedded within respiratory cycles;
(2) use the fine respiratory cycle features to predict vigilance states. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

(1) To run MouseBreathmetrics:
MathWorks Matlab (>2018b) is required to run the scripts. Scripts have been tested using Microsoft Windows 10. No special hardware is required. 
Yet, you need the buzcode-master (https://github.com/buzsakilab/buzcode) in your Matlab path and the Matlab Signal Processing Toolbox installed.

To extract respiration raw data, inspect the signal and perform individual cycle extraction, add the folder 
"\MouseBreathMetricsMaster" to your Matlab path and follow the instructions in the script called "TestRespiratorySignal" of this GitHub directory

Briefly, TestRespiratorySignal.m is the main wrapper script. 
It loads the respiration signal (by default in the RawData folder provided in this gitHub), it shows the intervals with exploitable respiratory signal (i.e. "VisuallyInspectSniffSignalForSniffInt"), and it calls the wrapper function "MouseBreathMetricsWrapper". 

The script uses as an option the StatesIntervals variable which is provided for the demo file (in the RawData folder). This variable can be generated based on the output of any state scoring method. It contains the time intervals corresponding to the different states (NREM, REM, Wake) of the recorded session. With this StatesIntervals variable, MouseBreathmetrics can be run in a state-dependant manner (see Methods in Casali et al., 2026) and generates as an output which will differ from the state-blind version.

In the paper, we used the results "StateBlind" to validate the notion that resp signal differs across states. The CNN was built using all the cycle info from "StateBlind" across sessions.
The rest of the results come from the "StateDependent" which are obtained by examining respiration in each valid sniff block of the same state. 
The expected run time for the demonstration session data is < 1 hr with a regular analysis computer. 

(2) To predict vigilance states with CNN:
For the prediction of vigilance states based on respiratory features, open the script RespirationBasedStatePrediction.ipynb using the Jupyter interface for Python (3.0).
On top of standard modules, Tensorflow (2.0), Numpy and Scipy modules are required. Follow the step-by-step instructions of the Jupyter notebook.

Demonstration data are provided in the 3C060-S16 folder.

Python scripts have been tested using Microsoft Windows 10, 11 and Ubuntu 24.  No special hardware is required, but a GPU computing can accelerate the computation.

The expected run time for the demonstration data is 15 min.


All software codes will be provided under GNU GPLv3 licence.


