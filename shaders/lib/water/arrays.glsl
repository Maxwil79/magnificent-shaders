	const float weightArray[numWaves] = float[numWaves] (
		1.0,
		8.0,
		15.0,
		0.3
	);

	vec2 pArray[numWaves] = vec2[numWaves] (
		(p / 1.6) + waveTime * vec2(0.03, 0.07),
		(p / 3.1) + waveTime * vec2(0.08, 0.06),
		(p / 4.7) + waveTime * vec2(0.07, 0.10),
		(p / 8.9) + waveTime * vec2(0.04, 0.02)
	);

	const vec2 scaleArray[numWaves] = vec2[numWaves] (
		vec2(2.0, 1.4),
		vec2(1.7, 0.7),
		vec2(1.0, 1.2),
		vec2(1.0, 0.8)
	);

	vec2 translationArray[numWaves] = vec2[numWaves] (
		vec2(pArray[0].y * 0.0, pArray[0].x * 0.1),
		vec2(pArray[1].y * 0.0, pArray[1].x * 0.8),
		vec2(pArray[2].y * 1.5, pArray[2].x * 0.0),
		vec2(pArray[3].y * 1.5, pArray[3].x * 0.0)
	);

	const float weightArray2[numWaves] = float[numWaves] (
		1.0,
		8.0,
		15.0,
		0.45
	);

	vec2 pArray2[numWaves] = vec2[numWaves] (
		(p2 / 1.6) + waveTime * vec2(0.03, 0.07),
		(p2 / 3.1) + waveTime * vec2(0.08, 0.06),
		(p2 / 4.7) + waveTime * vec2(0.07, 0.10),
		(p2 / 8.9) + waveTime * vec2(0.04, 0.02)
	);

	const vec2 scaleArray2[numWaves] = vec2[numWaves] (
		vec2(2.0),
		vec2(1.7),
		vec2(1.0),
		vec2(15.0)
	);

	vec2 translationArray2[numWaves] = vec2[numWaves] (
		vec2(pArray2[0].y * 0.0, pArray2[0].x * 0.0),
		vec2(pArray2[1].y * 0.0, pArray2[1].x * 0.0),
		vec2(pArray2[2].y * 0.0, pArray2[2].x * 0.0),
		vec2(pArray2[3].y * 0.0, pArray2[3].x * 0.0)
	);

	const float weightArray3[numWaves] = float[numWaves] (
		1.0,
		8.0,
		15.0,
		0.45
	);

	vec2 pArray3[numWaves] = vec2[numWaves] (
		(p / 1.6) + waveTime * vec2(0.03, 0.07),
		(p / 3.1) + waveTime * vec2(0.08, 0.06),
		(p / 4.7) + waveTime * vec2(0.07, 0.10),
		(p / 8.9) + waveTime * vec2(0.04, 0.02)
	);

	const vec2 scaleArray3[numWaves] = vec2[numWaves] (
		vec2(2.0, 1.4),
		vec2(1.7, 0.7),
		vec2(1.0, 1.2),
		vec2(15.0, 30.8)
	);

	vec2 translationArray3[numWaves] = vec2[numWaves] (
		vec2(pArray3[0].y * 0.0, pArray3[0].x * 0.0),
		vec2(pArray3[1].y * 0.0, pArray3[1].x * 0.0),
		vec2(pArray3[2].y * 0.0, pArray3[2].x * 0.0),
		vec2(pArray3[3].y * 0.0, pArray3[3].x * 0.0)
	);