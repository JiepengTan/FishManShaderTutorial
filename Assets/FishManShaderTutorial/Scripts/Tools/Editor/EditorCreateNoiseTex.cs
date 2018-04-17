using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class EditorCreateNoiseTex {
    static Texture2D texMatrix;
    public static int wid = 512;
    public static int hei = 512;
    public static int scale = 10;
    public static int bordPixelNum = 16;

    public static string perlinNoiseTexPath = "/Textures/PerlinNoise.png";
    public static string whiteNoiseTexPath = "/Textures/WhiteNoise.png";

    [MenuItem("Tool/CreatePerlinNoiseTex")]
    public static void CreatePerlinNoiseTex() {
        Color[] colors = new Color[wid * hei];
        for (int i = 0; i < hei; i++) {
            for (int j = 0; j < wid; j++) {
                colors[i * wid + j].r = Mathf.PerlinNoise(1.0f * i / hei * scale+ 0, 1.0f * j / wid * scale+0);
                colors[i * wid + j].g = Mathf.PerlinNoise(1.0f * i / hei * scale+ 101, 1.0f * j / wid * scale+101);
                colors[i * wid + j].b = Mathf.PerlinNoise(1.0f * i / hei * scale+ 217, 1.0f * j / wid * scale+217);
                colors[i * wid + j].a = Mathf.PerlinNoise(1.0f * i / hei * scale+ 331, 1.0f * j / wid * scale+331);
            }
        }
        // 让边界变得连续
        SmoothBorder(colors);
        SaveToPic(colors, perlinNoiseTexPath);
    }
    [MenuItem("Tool/CreateWhiteNoiseTex")]
    public static void CreateWhiteNoiseTex() {
        Color[] colors = new Color[wid * hei];
        for (int i = 0; i < hei; i++) {
            for (int j = 0; j < wid; j++) {
                colors[i * wid + j].r = WhiteNoise();
                colors[i * wid + j].g = WhiteNoise();
                colors[i * wid + j].b = WhiteNoise();
                colors[i * wid + j].a = WhiteNoise();
            }
        }
        // 让边界变得连续
        SmoothBorder(colors);
        SaveToPic(colors, whiteNoiseTexPath);
    }


    static private void SmoothBorder(Color[] colors) {
        int num = bordPixelNum;
        for (int j = 0; j < hei; j++) {
            float tr = colors[j * wid + num].r;
            float tl = colors[j * wid + wid - num - 2].r;
            for (int i = 0; i < num; i++) {
                float rper = 1.0f * (i + 1) / (num * 2 + 1);
                colors[j * wid + num - i - 1].r = Mathf.Lerp(tl, tr, 1.0f - rper);
                colors[j * wid + wid - num + i].r = Mathf.Lerp(tl, tr, rper);
            }
        }
        for (int j = 0; j < wid; j++) {
            float tc = colors[(hei - 1 - num) * wid + j].r;
            float bc = colors[(num) * wid + j].r;
            for (int i = 0; i < num; i++) {
                float rper = 1.0f * (i + 1) / (num * 2 + 1);
                colors[(num - i - 1) * wid + j].r = Mathf.Lerp(bc, tc, rper);
                colors[(hei - 1 - num + 1 + i) * wid + j].r = Mathf.Lerp(bc, tc, 1.0f - rper);
            }
        }
    }

    static float Hash12(Vector2 p) {
        float h = p.x * 127.1f + p.y * 311.7f;//  dot(p, Vector2(127.1, 311.7));
        float val = Mathf.Sin(h) * 43758.5453123f;
        return val - Mathf.Floor(val);
    }
    static float Noise(float x, float y) {
        return ValueNoise(new Vector2(x, y));
    }
    static float ValueNoise(Vector2 p) {
        float ix = Mathf.Floor(p.x);
        float iy = Mathf.Floor(p.y);
        Vector2 i = new Vector2(ix, iy);
        float fx = p.x - ix;
        float fy = p.y - iy;
        Vector2 u = new Vector2(fx * fx * (3.0f - 2.0f * fx), fy * fy * (3.0f - 2.0f * fy));
        return -1.0f + 2.0f * Mathf.Lerp(Mathf.Lerp(Hash12(i + new Vector2(0.0f, 0.0f)),
                         Hash12(i + new Vector2(1.0f, 0.0f)), u.x),
                   Mathf.Lerp(Hash12(i + new Vector2(0.0f, 1.0f)),
                         Hash12(i + new Vector2(1.0f, 1.0f)), u.x), u.y);
    }
    static float WhiteNoise() {
        return Random.value;
    }
    static void SaveToPic(Color[] colors, string relPath) {
        texMatrix = new Texture2D(wid, hei);
        texMatrix.SetPixels(colors);
        texMatrix.Apply();
        byte[] bytes = texMatrix.EncodeToPNG();
        // 将字节保存成图片，这个路径只能在PC端对图片进行读写操作  
        var path = ConstVar.ProjectDir + relPath;
        System.IO.File.WriteAllBytes(path, bytes);
        UnityEditor.AssetDatabase.ImportAsset(path);
        UnityEditor.AssetDatabase.Refresh();
    }

}
