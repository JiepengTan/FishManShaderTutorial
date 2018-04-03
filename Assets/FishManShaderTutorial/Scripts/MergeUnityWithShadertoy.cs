using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class MergeUnityWithShadertoy : PostEffectsBase {

	public Shader shader;
	private Material _mat = null;

	public Material material {  
		get {
			_mat = CheckShaderAndCreateMaterial(shader, _mat);
			return _mat;
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

    public Texture2D _NoiseTex;
    public Vector4 _LoopNum;

    void OnEnable() {
		camera.depthTextureMode |= DepthTextureMode.Depth;
	}
	
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
            SetRay();
            material.SetTexture("_NoiseTex", _NoiseTex);
            material.SetVector("_LoopNum", _LoopNum);
            
            Graphics.Blit(src, dest, material);
        } else {
			Graphics.Blit(src, dest);
		}
	}

    private void SetRay() {
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
        material.SetMatrix("_UnityMatVP", frustumCorners);
    }
}
