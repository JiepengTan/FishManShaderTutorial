using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class CreateNoiseTex : MonoBehaviour {
    Texture2D texMatrix;
    public int wid = 256;
    public int hei = 256;
    public int scale = 30;
    public int bordPixelNum = 16;
    // Use this for initialization
    void Start () {
        Debug.Log("CreateNoiseTex at " + Application.dataPath);
        Color[] colors = new Color[wid * hei];
        for (int i = 0; i < hei; i++) {
            for (int j = 0; j < wid; j++) {
                colors[i * wid + j].r = Mathf.PerlinNoise(1.0f * i / hei * scale, 1.0f * j / wid * scale);
                colors[i * wid + j].a = 1.0f;
            }
        }
        // 让边界变得连续
        SmoothBorder(colors);
        UpdateRenderInfo(colors);
    }

    private void SmoothBorder(Color[] colors) {
        int num = bordPixelNum;
        for (int j = 0; j < hei; j++) {
            float tr = colors[j * wid + num].r;
            float tl = colors[j * wid + wid - num - 2].r;
            for (int i = 0; i < num ; i++) {
                float rper = 1.0f*(i + 1) / (num * 2 + 1) ;
                colors[j * wid + num - i-1].r = Mathf.Lerp(tl, tr, 1.0f- rper);
                colors[j * wid +wid - num +i].r = Mathf.Lerp(tl,tr,rper);
            }
        }
        for (int j = 0; j < wid; j++) {
            float tc = colors[(hei  - 1 - num) * wid + j].r;
            float bc = colors[(num ) * wid + j].r;
            for (int i = 0; i < num; i++) {
                float rper = 1.0f * (i + 1) / (num * 2 + 1);
                colors[(num -i-1) * wid + j].r = Mathf.Lerp(bc, tc, rper);
                colors[(hei-1 -num +1 + i ) * wid + j].r = Mathf.Lerp(bc, tc, 1.0f - rper);
            }
        }
    }

    float hash(Vector2 p) {
        float h = p.x * 127.1f + p.y * 311.7f;//  dot(p, Vector2(127.1, 311.7));
        float val = Mathf.Sin(h) * 43758.5453123f;
        return val - Mathf.Floor(val);
    }
    float Noise(float x, float y) {
        return Noise(new Vector2(x, y));
    }
    float Noise(Vector2 p) {
        
#if TEXTURE_NOISE
				return tex2Dlod(_NoiseTex,float4(p,0.,0.)).r;
#else
        float ix = Mathf.Floor(p.x);
        float iy = Mathf.Floor(p.y);
        Vector2 i = new Vector2(ix, iy);
        float fx = p.x - ix;
        float fy = p.y - iy;
        Vector2 u = new Vector2(fx * fx * (3.0f - 2.0f * fx), fy * fy * (3.0f - 2.0f * fy));
        return -1.0f + 2.0f * Mathf.Lerp(Mathf.Lerp(hash(i +new Vector2(0.0f, 0.0f)),
                         hash(i + new Vector2(1.0f, 0.0f)), u.x),
                   Mathf.Lerp(hash(i + new Vector2(0.0f, 1.0f)),
                         hash(i + new Vector2(1.0f, 1.0f)), u.x), u.y);
#endif

    }

    void UpdateRenderInfo(Color[] colors) {
        texMatrix = new Texture2D(wid,hei);
        texMatrix.SetPixels(colors);
        texMatrix.Apply();
        byte[] bytes = texMatrix.EncodeToPNG();
        // 将字节保存成图片，这个路径只能在PC端对图片进行读写操作  
        System.IO.File.WriteAllBytes(Application.dataPath + "/CreateNoise.png", bytes);
#if UnityEditor
        UnityEditor.AssetDatabase.Refresh();
#endif
    }

}
