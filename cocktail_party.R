# This file contains the cocktail-party algorithm!
# Just source the file and run 'run_test()'. You might
# need to find a player suitable for your platform.
# Note: This version of the cocktail-party algorithm
# only separates two sources from two signals.

SOUND_FILE_1 = "./partysound/mix1.wav"
SOUND_FILE_2 = "./partysound/mix2.wav"
WAV_PLAYER = '/usr/bin/afplay' ## Suitable player on mac
VISUALIZATION_FILE = './cocktail_party.png'


run_test <- function(play_sounds=TRUE, visualization=FALSE){
	## Install if needed!
	library(tuneR)
		
	# Load files:
	a <- readWave(filename=SOUND_FILE_1)
	b <- readWave(filename=SOUND_FILE_2)

	# Sound in raw number format
	z <- cbind(a@left, b@left)

	# Pass the task to cocktail_party() which handles the heavy lifting:	
	original_sources <- cocktail_party(z, visualization=visualization)

	if(play_sounds){
		# Set to wave-format for playback:
		w1 <- Wave(left=original_sources$channel1, samp.rate=8000, bit=8)
		w1 <- normalize(w1, unit='8')
		w2 <- Wave(left=original_sources$channel2, samp.rate=8000, bit=8)
		w2 <- normalize(w2, unit='8')
	
		# Play original samples and separated sources:
		setWavPlayer(WAV_PLAYER)
		print("Recording 1 now playing")
		play(a)
		print("Recording 2 now playing")
		play(b)
		print("Estimated original source 1 now playing")
		play(w1)
		print("Estimated original source 2 now playing")
		play(w2)
	}
	
	return(original_sources)
}


kurtosis <- function(input){
	# This function calculates the sample estimate for the kurtosis of the input.
	# Input obviously Nx1
	# kurtosis is E(x^4) - 3(E(x^2))^2
	# 1. Center data
	input <- input - mean(input)
	# Formula for kurtosis :)
	kurt <- 1 / dim(input)[1] * sum(input^4) - 3 * (1 / dim(input)[1] * sum(input^2))^2
	return(kurt)
}


whiten <- function(data){
	# This function whitens the input data, i.e. removes mean and normalies
	# (co)variance.
	# Assuming samples in rows
	# Center data:
	for(i in 1:dim(data)[2]){
		data[, i] <- data[, i] - mean(data[, i])
	}
	# Calculate covariance matrix
	# Scaling is actually unimportant for the process...
	data_cov <- 1 / (dim(data)[1] - 1) * t(data) %*% data 
	# Do an eigenvalue decomposition
	EVD <- eigen(data_cov)
	# Create the inverse diagonal matrix with singular values
	d_inv <- diag(1 / sqrt(EVD$values))
	# Extract V
	V <- EVD$vectors
	# Whiten data
	white_data <- data %*% V %*% d_inv  ## %*% t(V) ## don't remove the rotation.
	# Return whitened data:
	return(white_data)
}


cocktail_party <- function(input, mu=0.001, convergence=1e-10, visualization=FALSE){
	# This function separates the original signals from the input. It basically
	# is an implementation of independent component analysis (ICA).
	# 'mu' is step-size for gradient descent
	# This only finds one local optimum. In a 2-d case, the other one is 
	# perpendicular to the found one...
	# With random restarts, we could find multiple such optima. 
	# Whiten data:
	white_data <- whiten(input)
	
	# Insert loop here to find multiple w's. Also insert 
	# orthogonalization criteria in normalization.
	# Basically "orthogonalization" happens by removing the components in w_new
	# that are projected on already found w_i's and then normalizing its length.
	
	# 1. Start with random vector w of length 1:
	w <- matrix(rnorm(dim(input)[2]), nrow=dim(input)[2], ncol=1) 
	w <- w/as.numeric(sqrt(t(w) %*% w))
	# Estimate kurtosis of whitened data projected onto w:
	kurt_tmp_this <- kurtosis(white_data %*% w)
	kurt_tmp_previous <- -1e15
	# Loop tests for convergence:
	while(kurt_tmp_this - kurt_tmp_previous > convergence){
		# 2. Estimate gradient for w^t*x and take small step in direction of it
		# gradient = 4*sign(kurtosis(z*w))*(E(z*(w^t*z)^3) -3w||w||^2 )
		grad <- sign(kurtosis(white_data %*% w)) * 
					(1 / dim(input)[1] * t(white_data) %*% 
					(white_data %*% w)^3 - 3 * w)
			# The -3*w could be dropped as it is aligned with w
			# and will only decrease the magnitude of the projection of the 
			# first part on the sphere ||w||=1.
		# Could also replace the next with a fixed point iteration and 
		# not care about step size. Supposedly converges faster. Works
		# because w is a sphere and w_new is always projected back to
		# the unit sphere.
		w <- w + mu * grad 
		# 4. Normalize w to |w| = 1 (unit length!)
		w <- w / as.numeric(sqrt(t(w) %*% w))
		# 5. Test convergence
		kurt_tmp_previous <- kurt_tmp_this
		kurt_tmp_this <- kurtosis(white_data %*% w)
		# 6. Repeat 2-5 until convergence
		# Weirdly enough, the resulting vector should have an angle of 45 degrees
		# from the horizontal axis when the whitened data is left as is and not
		# "returned" to the original rotation.
	}
	
	if(visualization){
		# This is what the whitened data looks like:
		par(mfrow=c(1, 2))
   		plot(input, col="#FF000020", pch=16, asp=1, main="Original data")
		plot(white_data, col="#00FF0020", pch=16, asp=1, main="Whitened data")
		# Project the data onto the vector r and multiply by r to project
		# data back to original basis for visualization.
		c <- cbind(as.numeric(white_data %*% w) * w[1, ], 
				   as.numeric(white_data %*% w) * w[2, ])
		#c <- cbind(as.numeric(input %*% w), as.numeric(input %*% w))
		points(c, col="#0000FF20", pch=16)
		# arrows(z[, 1], z[, 2], c[, 1], c[, 2], col="#00000010", code=0)
		arrows(white_data[, 1], white_data[, 2], c[, 1], c[, 2],
			   col="#00000010", code=0)

	}

	# Rotate r 90 degrees to get other component.
	# Second component is perpendicular to first!
	phi <- pi / 2
	rot <- matrix(c(cos(phi), -sin(phi), sin(phi), cos(phi)), nrow=2, ncol=2)
	# Original sources:
	channel1 <- white_data %*% w
	channel2 <- white_data %*% rot %*% w

	return(list('channel1' = channel1, 'channel2' = channel2))
}




