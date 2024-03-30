# ISETBioJandJ

This respository contains data and code used in "Theoretical Impact of Chromatic Aberration Correction on Visual Acuity"
by Nankivil, Cottaris, & Brainard (2024, under review).

The data are monochromatic wavefront aberration functions for the 18 subjects considered in the paper (4 mm diameter pupil), along with point spread functions derived from the monochromatic aberrations for various combinations of pupil size a amounts of chromatic aberration, as described in the manuscript.  The subjects are ordered as in the manuscript, with Subject 1 having the best optical quality, Subject 9 the median, and Subject 18 the worst.  
	The wavefront abberation functions are in directory data/WaveAberrations.  There is a .csv file for each subject. and a plot is provided of the monochromatic PSF corresponding to each aberration.  The file in that directory, Zernike data from eye.docx, provides information about the wavefront aberration data, including a reference to the paper in which the measurements were described. [Need to add information about the spatial sampling in the pupil plane to the document, although one could deduce this from the fact that the pupil was 4mm. Might also explain the code that leads to the filenames - is the first number the defocus that was added to optimize Sthrel? In D or uM? What do the "astig_axis_0" versus "no_atig0" strings denote?_"]
	 
ISETBio implementation of a 4-AFC tumbling E experiment using custom PSFs and custom display SPDs.
The simulation characterizes performance as a function of the angular size of the letter E.

Noise-free cone mosaic responses to stimuli of different sizes (0.04, 0.08, and 0.104 degs) which result in different performance levels (Pcorrect: 0.26, 0.4, and 0.6) are shown below.
These results are for a 300 msec integration time.

<img
  src="/figures/noisefree.png"
  alt="Alt text"
  title="Noise-free cone mosaic response instances"
  style="display: inline-block; margin: 0 auto; max-width: 300px">
  
---
  
Noisy response instances and noise-free cone mosaic responses to a 0.152 degs which results in Pcorrect = 0.95 are shown below.
These results are also for a 300 msec integration time.

<img
  src="/figures/noisy.png"
  alt="Alt text"
  title="Noisy cone mosaic response instances"
  style="display: inline-block; margin: 0 auto; max-width: 300px">

---

The custom PSFs employed in these simulations are depicted below for 500nm, 550nm, and 600nm on top of the employed cone mosaic.

<img
  src="/figures/PSFsAndConeMosaic.png"
  alt="Alt text"
  title="Noisy cone mosaic response instances"
  style="display: inline-block; margin: 0 auto; max-width: 30px">
  
