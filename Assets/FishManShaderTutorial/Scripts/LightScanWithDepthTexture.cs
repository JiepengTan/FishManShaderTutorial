using UnityEngine;
using System.Collections;

public class ScanWithDepthTexture : PostEffectsBase {

	public Shader fogShader;

    public Transform centerTargetTrans;
    public float _RingIntensity;
    public float _RingWidth;//环半径
    public float spreadSpeed;//扩散速度
    public float maxRange = 100;
    private float _InnerRange;

    public Texture _TileTex;
    public float _TileSize;
    public float _TileIntensity;
    public Color _TileColor;
    
    public Texture _NoiseTex;
    public float _NoiseCellSize;
    public Color _NoiseCellColor;

    public Color _EdgeColor = Color.white;

    private Material fogMaterial = null;
    
	public Material material {  
		get {
			fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}  
	}

	private Camera myCamera;
	public new Camera camera {
		get {
			if (myCamera == null) {
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}

	private Transform myCameraTransform;
	public Transform cameraTransform {
		get {
			if (myCameraTransform == null) {
				myCameraTransform = camera.transform;
			}

			return myCameraTransform;
		}
    }
    
    private void Update()
    {
        _InnerRange = spreadSpeed * Time.realtimeSinceStartup % maxRange;
    }

    void OnEnable() {
		camera.depthTextureMode |= DepthTextureMode.Depth;
	}
	
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			Matrix4x4 frustumCorners = Matrix4x4.identity;

			float fov = camera.fieldOfView;
			float near = camera.nearClipPlane;
			float aspect = camera.aspect;

			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toRight = cameraTransform.right * halfHeight * aspect;
			Vector3 toTop = cameraTransform.up * halfHeight;

			Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
			float scale = topLeft.magnitude / near;

			topLeft.Normalize();
			topLeft *= scale;

			Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
			topRight.Normalize();
			topRight *= scale;

			Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
			bottomLeft.Normalize();
			bottomLeft *= scale;

			Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= scale;

			frustumCorners.SetRow(0, bottomLeft);
			frustumCorners.SetRow(1, bottomRight);
			frustumCorners.SetRow(2, topRight);
			frustumCorners.SetRow(3, topLeft);

			material.SetMatrix("_FrustumCornersRay", frustumCorners);
            material.SetVector("_SrcCenterPos", centerTargetTrans.position);
            material.SetFloat("_InnerRange", _InnerRange);
            material.SetFloat("_RingWidth", _RingWidth);
            material.SetFloat("_RingIntensity", _RingIntensity);

            material.SetTexture("_TileTex", _TileTex);
            material.SetFloat("_TileSize", _TileSize);
            material.SetFloat("_TileIntensity", _TileIntensity);
            material.SetColor("_TileColor", _TileColor);
            

            material.SetTexture("_NoiseTex", _NoiseTex);
            material.SetFloat("_NoiseCellSize", _NoiseCellSize);
            material.SetColor("_NoiseCellColor", _NoiseCellColor);
            
            material.SetColor("_EdgeColor", _EdgeColor);

            Graphics.Blit (src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
