using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;



 public class EditorCreateTerrialMap {
    static Texture2D texMatrix;
    public static int wid = 512;
    public static int hei = 512;
    public static int scale = 10;
    public static int bordPixelNum = 16;

    public static string TerrialMapTexPath = "/Textures/TerrialMap.png";


    [MenuItem("Tool/CreateTerrialMap")]
    public static void CreateWhiteNoiseTex() {
        //FastNoise fn = new FastNoise();
        //
        //Color[] colors = new Color[wid * hei];
        //for (int i = 0; i < hei; i++) {
        //    for (int j = 0; j < wid; j++) {
        //        var val = fn.GetPerlinFractal(i, j); ;
        //        colors[i * wid + j].r = val;
        //        colors[i * wid + j].a = 1.0f;
        //    }
        //}
        //SaveToPic(colors, TerrialMapTexPath);
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
