# V2V Communication 
These are the scripts associated with the 2022 research paper on the effects of Vehicle-to-Vehicle communication. 
They have been tested and confirmed to run correctly in Matlab R2022b. 

`EqWithFalsePositives.m` creates an interactive GUI to explore the properties of signaling equilibria, including which parameter combinations cause them to occur, the behavior they cause, and the incurred accident probability and social cost. 
Due to computational and visual limitations, all calculations done in this script assume that beta=1. 

`JournalPaperGraphics.m` generates all the plots seen in the paper. 
By default, the figures will only be displayed, but simple changes to the script can cause them to be saved to your machine. 

All scripts assume that the root repository folder and the subfolder `Graphics` are on the current Matlab path. 
