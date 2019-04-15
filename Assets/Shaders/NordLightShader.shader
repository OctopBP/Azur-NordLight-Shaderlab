Shader "Custom/Shader"
{
	Properties
	{
        _Color1 ("Color 1", Color) = (0.0, 0.0, 0.0, 0.0)
        _Color2 ("Color 2", Color) = (0.0, 0.0, 0.0, 0.0)
        _Color3 ("Color 3", Color) = (0.0, 0.0, 0.0, 0.0)

        _MainTex ("Main Texture", 2D) = "white" {}

        _SpeedRight ("Speed Right", Float) = 0.1
        _SpeedLeft ("Speed Left", Float) = -0.1

        _TilingRay ("Ray Tiling", Float) = 1.0

        _MainPower ("Main Power", Range(0.0, 1.0)) = 1.0
        _RayPower ("Ray Power", Range(0.0, 1.0)) = 1.0
        _RayLerp ("Ray Lerp", Range(0.0, 1.0)) = 1.0

        _LineNoiseTex ("Line Noise Texture", 2D) = "white" {}
        _LineNoiseSpeed ("Line Noise Speed", Float) = 0.0
		
        _DisplacementSpeed ("Displacement Speed", Float) = 0.0
        _Displacement ("Displacement", Vector) = (0.0, 0.0, 0.0, 0.0)
		
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseSpeed ("Noise Speed", Float) = 0.0
	}
	SubShader
	{
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

		Cull Off
		ZWrite On
		ZTest NotEqual

		Pass
		{
            Blend SrcAlpha OneMinusSrcAlpha
            
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv1 : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float2 uv3 : TEXCOORD2;
				float2 uv4 : TEXCOORD3;
			};

			// Main textures
            sampler2D _MainTex;
            float4 _MainTex_ST;

			float _SpeedLeft;
			float _SpeedRight;

			float4 _Color1;
			float4 _Color2;
			float4 _Color3;
			
			float _TilingRay;

			float _MainPower;
			float _RayPower;
			float _RayLerp;

			// Texture for noise alpha
            sampler2D _LineNoiseTex;
            float4 _LineNoiseTex_ST;

			float _LineNoiseSpeed;

			float _DisplacementSpeed;
			float4 _Displacement;

			// Texture for global alpha
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

			float _NoiseSpeed;

			v2f vert(appdata v)
			{
				// Изгибаем модель
				float uvx = v.uv.x + _Time * _DisplacementSpeed;
				float4 noiseTex = tex2Dlod(_LineNoiseTex, float4(uvx, v.uv.y, 0.0, 0.0));				

				v2f o;
				o.pos = UnityObjectToClipPos(v.pos + _Displacement * (noiseTex.b - 0.5));

				// MainTex1UV
				float2 uv = v.uv;
				uv.x += _Time * _SpeedRight;
				o.uv1 = uv * _MainTex_ST.xy + _MainTex_ST.zw;
		
				// MainTex2UV
				uv = v.uv;
				uv.x += _Time * _SpeedLeft;
				o.uv2 = uv * _TilingRay + _MainTex_ST.zw;

				// LineNoiseUV
				uv = v.uv;
				uv.x += _Time * _LineNoiseSpeed;
				o.uv3 = uv * _LineNoiseTex_ST.xy + _LineNoiseTex_ST.zw;
				
				// NoiseUV
				float4 noiseUV = v.pos * _NoiseTex_ST.y;
				noiseUV = (noiseUV.x + noiseUV.z) / 3;

				_NoiseTex_ST.z += _Time * _NoiseSpeed;
				o.uv4 = float2(noiseUV.x, noiseUV.z) * _NoiseTex_ST.xy + _NoiseTex_ST.zw;

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float4 mainTex1 = tex2D(_MainTex, i.uv1);
				float4 mainTex2 = tex2D(_MainTex, i.uv2);

				float4 lineNoiseTex = tex2D(_LineNoiseTex, i.uv3);
				float4 noiseTex = tex2D(_NoiseTex, i.uv4);

				float4 color1 = lerp(_Color1, _Color2, fmod(i.uv1.g, 1));

				// Собираем результат
                float4 color;

				color.rgb = lerp(color1, _Color3, mainTex2.g * lineNoiseTex.r * _RayLerp);
				color.a = ((mainTex1.r* _MainPower) + (mainTex1.g * mainTex2.b * _RayPower)) * pow(noiseTex.r, 3);

				return color;
			}
			ENDCG
		}
	}
}