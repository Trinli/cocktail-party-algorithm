## This file contains the cocktail-party algorithm!
## Just source the file and run 'run_test()'. You might
## need to find a player suitable for your platform.

SOUND_FILE_1 = "./partysound/mix1.wav"
SOUND_FILE_2 = "./partysound/mix2.wav"
WAV_PLAYER = '/usr/bin/afplay'
VISUALIZATION_FILE = './cocktailParty.png'


run_test <- function(){
	## Install if needed!
	library(tuneR)
	
	#############
	## LOAD FILES
	#############
	a <- readWave(filename=SOUND_FILE_1)
	b <- readWave(SOUND_FILE_2)
	## Should data be centralized?
	z <- cbind(a@left, b@left) ## Sound in raw number format?
	
	r <- cocktail_party(z)
	plot(z, col="#FF000020", pch=16)
	c <- cbind(as.numeric(z%*%r)*r[1, ], as.numeric(z%*%r)*r[2, ])
	points(c, col="#0000FF20", pch=16)
	arrows(z[, 1], z[, 2], c[, 1], c[, 2], col="#00000010", code=0)
	
	phi=pi/2
	rot <- matrix(c(cos(phi), -sin(phi), sin(phi), cos(phi)),nrow=2, ncol=2 )
	channel1 <- z%*%r ## Separate sources
	channel2 <- z%*%rot%*%r
	
	w1 <- Wave(left=channel1, samp.rate=8000, bit=8)
	w1 <- normalize(w1, unit='8')
	w2 <- Wave(left=channel2, samp.rate=8000, bit=8)
	w2 <- normalize(w2, unit='8')
	
	######################
	## SET SUITABLE PLAYER
	######################
	setWavPlayer(WAV_PLAYER) ## Suitable player on mac
	print("Recording 1 now playing")
	play(a)
	print("Recording 2 now playing")
	play(b)
	print("Estimated original source 1 now playing")
	play(w1)
	print("Estimated original source 2 now playing")
	play(w2)
	
	
	# Plot awesome image of transformation
	print("Storing visualization.")
	png(VISUALIZATION_FILE, width=800, height=800)
	plot(z, col="#FF000090", pch=16)
	c <- cbind(as.numeric(z%*%r)*r[1, ], as.numeric(z%*%r)*r[2, ])
	points(c, col="#0000FF90", pch=16)
	arrows(z[, 1], z[, 2], c[, 1], c[, 2], col="#00000060", code=0)
	dev.off()

}


kurtosis <- function(input){
	## Input obviously Nx1
	## kurtosis is E(x^4) - 3(E(x^2))^2
	## 1. Center data
	input <- input - mean(input)
	# Formula for kurtosis :)
	kurt <- 1/dim(input)[1]*sum(input^4) - 3*(1/dim(input)[1]*sum(input^2))^2
	return(kurt)
}


whiten <- function(data){
	## Assuming samples in rows
	## Center data:
	for(i in 1:dim(data)[2]){
		data[, i] <- data[, i] - mean(data[, i])
	}
	## Calculate covariance matrix
	## Scaling is actually unimportant for the process...
	data_cov <- 1/(dim(data)[1]-1) * t(data) %*% data 
	## Do an eigenvalue decomposition
	EVD <- eigen(data_cov)
	## Create the inverse diagonal matrix with singular values
	d_inv <- diag(1/sqrt(EVD$values))
	## Extract V
	V <- EVD$vectors
	## Whiten data and rotate back to original basis
	white_data <- data %*% V %*% d_inv  ## %*% t(V) ## don't remove the rotation.
	## Return whitened data:
	return(white_data)
}


cocktail_party <- function(input, mu=0.001, convergence=1e-10){ ## Could also be called simply ICA...
	## No assumptions on #independent components or input dims
	## mu is step-size for gradient descent
	## This only finds one local optimum. In a 2-d case, the other one is 
	## perpendicular to the found one...
	## With random restarts, we could find multiple such optima. 
	## The starting points would not even have to be random, one in every
	## quadrant should do (as long as they don't hit a zero point).
	white_data <- whiten(input)
	## Gradient descent for ICA
	
	## Insert loop here to find multiple w's. Also insert 
	## orthogonalization criteria in normalization.
	## Basically "orthogonalization" happens by removing the components in w_new
	## that are projected on already found w_i's and then normalizing its length.
	
	## 1. Start with random vector w or length 1:
	w <- matrix(rnorm(dim(input)[2]), nrow=dim(input)[2], ncol=1) 
	w <- w/as.numeric(sqrt(t(w)%*%w))
	kurt_tmp_1 <- kurtosis(white_data%*%w)
	kurt_tmp_2 <- -1e15 ## Could cause problems. Replace by do-while -loop?
	## Loop tests for convergence:
	while(kurt_tmp_1-kurt_tmp_2 > convergence){
		## 2. Estimate gradient for w^t*x and take small step in direction of it
		## gradient = 4*sign(kurtosis(z*w))*(E(z*(w^t*z)^3) -3w||w||^2 )
		grad <- sign(kurtosis(white_data %*% w))*(1/dim(input)[1]*t(z)%*%(z%*%w)^3
			- 3*w) ## The -3*w can be dropped as it is aligned with w
			## and will only decrease the magnitude of the projection of the 
			## first part on the sphere ||w||=1.
		## Could also replace the next with a fixed point iteration and 
		## not care about step size. Supposedly converges faster. Works
		## because w is a sphere and w_new is always projected back to
		## the unit sphere.
		w <- w + mu*grad 
		## 4. Normalize w to |w| = 1 (unit length!)
		## Apparently sqrt(.) requires an explicit conversion for division to work..
		w <- w / as.numeric(sqrt(t(w)%*%w))
		## 5. Test convergence
		kurt_tmp_2 <- kurt_tmp_1 ## Does kurtosis flip sign between iterations? nope.
		kurt_tmp_1 <- kurtosis(white_data %*% w)
		## 6. Repeat 2-5 until convergence
	}
	return(w)
	## We could repeat the process for a number of random starting points w
	## until we find dim(input)[2] different w's that converge
}



