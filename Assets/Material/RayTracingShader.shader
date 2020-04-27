Shader "Unlit/RayTracingShader"
{
    Properties
    {
        _RefractColor("RefractGem1",Color)= (1,1,1,1)
        _ReflectColor("ReflectGem2",Color)= (1,1,1,1)
        _RefractColor01("Refract",Color)=(1,1,1,1)
        _SkyBox("Sky",Cube)="black"
        _MaxBounce("MaxBounce",Int)=0
        _DiamondIndex("DiamondR",vector)=(2.407, 2.427, 2.451, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            const float noInterT=-1.;

            int _MaxBounce;
			float3 _LightPos;
            samplerCUBE _SkyBox;
            float4 _RefractColor,_ReflectColor,_RefractColor01,_DiamondIndex;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 vertex : TEXCOORD1;
                float3 ray: TEXCOORD2;
                float4 pos: POSITION;
            };
            struct Ray
            {
                float3 origin;
                float3 direction;
            };
            struct Material
            {
                float3 ambi;
				float3 diff;
				float3 spec;
				float3 refleCol;
				float3 refraCol;
				float refleValue;
				float refraValue;
				float specPower;
				float texAlpha;
				float3 refraIndex;
            };
            struct Intersection
            {
                float3 pos;
                float t;
                float3 normal;
                bool isIn;
            };
            struct Light
            {   
                float3 pos;
                float3 col;
            };
            //init intersection 
            Intersection noIntersection()
            {
                Intersection inter;
                inter.pos=0;
                inter.t=noInterT;
                inter.normal=0;
                inter.isIn=false;

                return inter;
            }
            //if the ray is hitting a mesh triangle
            bool IntersectTriangle(float4 origin, float4 direction, float4 v0, float4 v1, float4 v2, inout Intersection intersect)
            {
                float t, u, v;

				// edge1
				float4 edge1 = v1 - v0;
		 
				// edge2
				float4 edge2 = v2 - v0;
		 
				// P
				float4 P = float4(cross(direction,edge2), 1);
		 
				// determinant
				float det = dot(edge1,P);
		 
				// keep det > 0, modify T accordingly
				float4 T;

				if( det >0 )
				{
					T = origin - v0;
				}
				else
				{
					T = v0 - origin;
					det = -det;
				}
		 
				// If determinant is near zero, ray lies in plane of triangle
				if( det < 0.0001f )
					return false;
		 
				// Calculate u and make sure u <= 1
				u = dot(T,P);
				if( u < 0.0f || u > det )
					return false;
		 
				// Q
				float4 Q = float4(cross(T,edge1), 1);
		 
				// Calculate v and make sure u + v <= 1
				v = dot(direction,Q);
				if( v < 0.0f || u + v > det )
					return false;
		 
				// Calculate t, scale parameters, ray intersects triangle
				t = dot(edge2,Q);
		 
				float fInvDet = 1.0f / det;
				t *= fInvDet;
				u *= fInvDet;
				v *= fInvDet;

				intersect.pos = origin + direction * t;
				intersect.t = t;
				intersect.normal = normalize(cross(edge1,edge2));
				intersect.isIn = dot(intersect.normal, direction) > 0;

				return true;
            }
            //if the ray is hitting bounding sphere
            bool IntersectSphere(float3 origin, float3 direction, float3 sphereCenter, float radius)
            {
                //right triangle equation a^2=c^2+b^2
                float3 a = sphereCenter-origin;
                float b = dot(a,direction);
                float c = sqrt(dot(a,a)-b*b);
                
                if(c>radius)
                    return false;
                else
                    return true;
            }
            //get background color
            float4 GetSky(float3 direction)
            {   
                float4 skyCol=texCUBE(_SkyBox,direction);
                return skyCol;
            }
            //set material parameters
            Material GetMat(int index)
            {
                Material mat;
                if(index==0)
                {
                    mat.ambi = 1;
					mat.diff = 1;
					mat.spec = 1;
					mat.refleCol = 1;
					mat.refraCol = 1;
					mat.refleValue = 0;
					mat.refraValue = 1;
					mat.specPower = 40;
					mat.texAlpha = 0;
					mat.refraIndex = _DiamondIndex;
                }
                else if(index==1)
                {
                    mat.ambi = 1;
					mat.diff = 1;
					mat.spec = 1;
					mat.refleCol = 1;
					mat.refraCol = 1;
					mat.refleValue = 1;
					mat.refraValue = 0;
					mat.specPower = 40;
					mat.texAlpha = 1;
					mat.refraIndex = 2.417;
                }
                else if(index==2)
                {
                    mat.ambi = 1;
					mat.diff = 1;
					mat.spec = 1;
					mat.refleCol = 0;
					mat.refraCol = _RefractColor;
					mat.refleValue = 0;
					mat.refraValue = 1;
					mat.specPower = 40;
					mat.texAlpha = 0;
					mat.refraIndex = 1.770;
                }
                else if(index==3)
                {
                    mat.ambi = 1;
					mat.diff = 1;
					mat.spec = 1;
					mat.refleCol = _ReflectColor;
					mat.refraCol = 0;
					mat.refleValue = 1;
					mat.refraValue = 0;
					mat.specPower = 40;
					mat.texAlpha = 0;
					mat.refraIndex = 1.770;
                }
                else
                {
                    mat.ambi = 1;
					mat.diff = 1;
					mat.spec = 1;
					mat.refleCol = 1;
					mat.refraCol = _RefractColor01;
					mat.refleValue = 0;
					mat.refraValue = 1;
					mat.specPower = 40;
					mat.texAlpha = 0;
					mat.refraIndex = 2.417;
                }
                return mat;
            }
            //if it is hitting an object, get the hitting pos and color it
            uniform float4 _Vertices[1000];
            bool GetNearestPos(Ray ray, inout Intersection minInter, inout int index, bool isHitting)
            {
                bool hit=false;
                for(int i=0;i<1000;)
                {
                    //_Vertices[0]=bounding sphere, _Vertices[1]=triangle length, _Vertices[2-n]=triangle vertices information
                    int triangleNum=_Vertices[i+1].x;
                    if(triangleNum==0||_Vertices[i].w==0)
                        break;

                    float3 sphereCenter=_Vertices[i].xyz;
                    float radius=_Vertices[i].w;
                    i += 2;
                    if(IntersectSphere(ray.origin,ray.direction,sphereCenter,radius))
                    {
                        for(int j=0;j<triangleNum;j+=3)
                        {
                            
                            Intersection inter=noIntersection();
                            if(IntersectTriangle(float4(ray.origin,1),float4(ray.direction,0),float4(_Vertices[i+j].xyz,1),
                            float4(_Vertices[i+j+1].xyz,1),float4(_Vertices[i+j+2].xyz,1),inter)&&inter.t>.0001)
                            {
                                hit=true;
                                //if hits, get the mat index to color
                                if(minInter.t==noInterT||inter.t<minInter.t)
                                {
                                    index=_Vertices[i+j].w;
                                    minInter=inter;
                                    if(minInter.isIn==isHitting)
                                        break;
                                }
                            }
                        }
                    }
                    i += triangleNum;
                }
                return hit;
            }
            //shading function, Lighting model
            float3 GetColor(Ray ray, Intersection inter, Material mat)
            {
                Light light;
				light.pos = _LightPos;
				light.col = 1;

                float3 c=mat.ambi;
                float2 uv= inter.pos.xz;
				float3 lightDir = normalize(light.pos - inter.pos);
				float3 viewDir = normalize(_WorldSpaceCameraPos - inter.pos);
                float3 diffc=max(0,dot(inter.normal,lightDir))*light.col*mat.diff;//lambert light model
                float3 reflc=normalize(reflect(-lightDir,inter.normal));//reflect vector
                float3 specc=pow(max(dot(reflc,viewDir),0),mat.specPower)*light.col*mat.spec;//phong light model

                c+=diffc+specc;
				return c;
            }
            //core function 
            float4 RayTracing(Ray ray, float3 splitCol)
            {
                Ray rayNext=ray;
                float4 result=0;
                float4 mask=1;
                bool isHitting=false;
                //float fresnelScale=0.2;

                for(int i=0;i<_MaxBounce && result.a<.99;i++)
                {
                    Intersection inter = noIntersection();
                    float4 col;
                    int index;
                    //if hits, calculate reflection and refraction 
                    if(GetNearestPos(rayNext,inter,index,isHitting))
                    {
                        Material mat = GetMat(index);
                        col=float4(GetColor(rayNext,inter,mat),1);
                        float alpha=mat.refleValue>0?1-mat.refleValue:1-mat.refraValue;//fully reflection alpha should = 0
                        result+=col*alpha*(1-result.a)*mask;
                        //accumulate color info by a color mask
                        if(mat.refleValue!=0)
                        {
                            mask*=float4(mat.refleCol,1);
                            //mask*= fresnelScale+pow(1-dot(rayNext.direction,inter.normal),5)*fresnelScale;
                        }
                        else
                            mask*=float4(mat.refraCol,1);

                        float3 normal=inter.normal * (inter.isIn?-1:1);

                        rayNext.origin=inter.pos;

                        //calculate the reflection and refraction
                        if(mat.refleValue!=0)
                            rayNext.direction = reflect(rayNext.direction,normal.xyz);
                        else
                        {
                            float refractIndex=dot(mat.refraIndex,splitCol);
                            refractIndex= inter.isIn? refractIndex:1/refractIndex;//snell law
                            float3 refraction=refract(rayNext.direction,normal,refractIndex);
                            if(dot(refraction,refraction)<.0001)
                                rayNext.direction=reflect(rayNext.direction,normal.xyz);
                            else
                            {
                                rayNext.direction=refraction;
                                isHitting=!isHitting;
                            }
                        }
                    }
                    else
                        break;
                }
                //sum results
                float4 skyCol=GetSky(rayNext.direction)*mask;
                result.rgb=result.xyz+skyCol;// * max(0,1-result.a);
                result.a=1;

                return dot(result,splitCol);
            }
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.vertex=v.vertex;

                //transform screen-space to camera-space, [0,1] to [-1,1]
                float4 Ray=mul(unity_CameraInvProjection,float4((v.uv-.5)*2,1,1));
                Ray.z*=-1;
                o.ray=Ray.xyz/Ray.w;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //calculate view position, camera's world position, view direction..
                float4 viewPos=float4(i.ray,1);
                float4 worldPos=mul(unity_CameraToWorld,viewPos);
                float3 viewDir=normalize(_WorldSpaceCameraPos-worldPos);

                //init ray
                Ray ray;
                ray.origin=_WorldSpaceCameraPos;
                ray.direction=-viewDir;

                //calculate raytracing in 3 color channel to create dispersion
                float4 col=0;
                col.r=RayTracing(ray,float3(1,0,0));
                col.g=RayTracing(ray,float3(0,1,0));
                col.b=RayTracing(ray,float3(0,0,1));
                return col;
            }
            ENDCG
        }
    }
}
