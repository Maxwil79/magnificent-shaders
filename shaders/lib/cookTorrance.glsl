vec3 radiance(
	vec3 n,		// macro surface normal
	vec3 l,		// direction from vertex to light
	vec3 v,		// direction from vertex to view
	// matt
	float m,	// roughness
	vec3 cdiff,	// diffuse  reflectance
	vec3 cspec,	// specular reflectance : F0
	// light
	vec3 clight	// light intensity
) {
	// half vector
	vec3 h = normalize( l + v );
	
	// dot
	float dot_n_h = max( abs( dot( n, h ) ), 0.001 );
	float dot_n_v = max( abs( dot( n, v ) ), 0.001 );
	float dot_n_l = max( abs( dot( n, l ) ), 0.001 );
	float dot_h_v = max( abs( dot( h, v ) ), 0.001 ); // dot_h_v == dot_h_l
	
	// Geometric Term
    // Cook-Torrance
    //          2 * ( N dot H )( N dot L )    2 * ( N dot H )( N dot V )
	// min( 1, ----------------------------, ---------------------------- )
	//                 ( H dot V )                   ( H dot V )
	float g = 2.0 * dot_n_h / dot_h_v;
	float G = min( min( dot_n_v, dot_n_l ) * g, 1.0 );
    
    // Normal Distribution Function ( cancel 1 / pi )
 	// Beckmann distribution
	//         ( N dot H )^2 - 1
	//  exp( ----------------------- )
	//         ( N dot H )^2 * m^2
	// --------------------------------
	//         ( N dot H )^4 * m^2
    float sq_nh   = dot_n_h * dot_n_h;
	float sq_nh_m = sq_nh * ( m * m );
	float D = exp( ( sq_nh - 1.0 ) / sq_nh_m ) / ( sq_nh * sq_nh_m );
    
	// Specular Fresnel Term : Schlick approximation
	// F0 + ( 1 - F0 ) * ( 1 - ( H dot V ) )^5
	vec3 Fspec = cspec + ( 1.0  - cspec ) * pow( 1.0 - dot_h_v, 5.0 );
	
	// Diffuse Fresnel Term : violates reciprocity...
	// F0 + ( 1 - F0 ) * ( 1 - ( N dot L ) )^5
	vec3 Fdiff = cspec + ( 1.0  - cspec ) * pow( 1.0 - dot_n_l, 5.0 );
	
	// Cook-Torrance BRDF
	//          D * F * G
	// ---------------------------
	//  4 * ( N dot V )( N dot L )
	vec3 brdf_spec = Fspec * D * G / ( dot_n_v * dot_n_l * 4.0 );
	
	// Lambertian BRDF ( cancel 1 / pi )
	vec3 brdf_diff = cdiff * ( 1.0 - Fdiff );
	
	// Punctual Light Source ( cancel pi )
	return ( brdf_spec + brdf_diff ) * clight * dot_n_l;	
}