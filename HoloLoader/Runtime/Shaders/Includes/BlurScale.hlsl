/*
 * This file is subject to the terms and conditions defined in
 * file 'README.md', which is part of this source code package.
 */

void BlurScale_float(float BlurScale, out float Iterations, out float Kernel)
{

	if (BlurScale == 0)
	{
		Iterations = 1;
		Kernel = 0;
	}
	else
	{
		int tempBS = BlurScale;

		Iterations = tempBS;
		Kernel = 1;

		

		if (tempBS > 20)
		{
			tempBS /= 2;
			Kernel += 1;
		}

		if (tempBS > 10)
		{
			tempBS /= 2;
			Kernel += 1;
		}

		if (tempBS > 5)
		{
			tempBS /= 2;
			Kernel += 1;
		}

		Iterations = tempBS;
	}


}


