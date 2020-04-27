using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RayTrace : MonoBehaviour
{
    public List<GameObject> meshObjects;
    public Material mat;
    public Light light;

    private List<Vector4> bounds = new List<Vector4>();

    private void OnEnable()
    {
        CalculateBounds();
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, mat);
    }
    void Update()
    {
        if (mat)
            PassDataToShader();
    }

    private void PassDataToShader()
    {
        List<Vector4> list = new List<Vector4>();

        int count = 0;

        //add sphere and triangles information to list and pass to shader
        foreach(GameObject gameObject in meshObjects)
        {
            Matrix4x4 localToWorld = gameObject.transform.localToWorldMatrix;
            Mesh mesh = gameObject.GetComponent<MeshFilter>().sharedMesh;
            Vector3 origin = localToWorld.MultiplyPoint(bounds[count]);
            Vector4 originGlobal = new Vector4(origin.x, origin.y, origin.z, bounds[count].w * gameObject.transform.lossyScale.x);
            list.Add(originGlobal);
            list.Add(new Vector4(mesh.triangles.Length, 0));
            count++;
            //set material info
            for(int i = 0; i < mesh.triangles.Length; i++)
            {
                Vector4 vec = localToWorld.MultiplyPoint(mesh.vertices[mesh.triangles[i]]);

                if (gameObject.name == "Quad")// 100 % reflection
                    vec.w = 1;

                if (gameObject.name == "5 Side Diamond")//no dispersion
                    vec.w = 2;

                if (gameObject.name == "GemSmall")//reflection
                    vec.w = 3;

                list.Add(vec);
            }
        }
        mat.SetVectorArray("_Vertices", list);
        mat.SetVector("_LightPos", light.transform.position);
    }
    void CalculateBounds()
    {
        foreach(GameObject gameObject in meshObjects)
        {
            Mesh mesh = gameObject.GetComponent<MeshFilter>().sharedMesh;
            Vector3 max = new Vector3(-Mathf.Infinity, -Mathf.Infinity, -Mathf.Infinity);
            Vector3 min = new Vector3(Mathf.Infinity, Mathf.Infinity, Mathf.Infinity);

            //tight the sphere by founding the minimal/max x,y,z on mesh
            foreach(Vector3 vert in mesh.vertices)
            {
                if (vert.x > max.x)
                    max.x = vert.x;
                if (vert.y > max.y)
                    max.y = vert.y;
                if (vert.z > max.z)
                    max.z = vert.z;
                if (vert.x < min.x)
                    min.x = vert.x;
                if (vert.y < min.y)
                    min.y = vert.y;
                if (vert.z < min.z)
                    min.z = vert.z;
            }
            float x = max.x - min.x;
            float y = max.y - min.y;
            float z = max.z - min.z;

            //find the sphere center
            Vector3 origin = new Vector3(0.5f * (max.x + min.x), 0.5f * (max.y + min.y), 0.5f * (max.z + min.z));

            //get min radius of sphere from objects' center
            float r = x > y ? x * .5f : y * .5f;
            r = r > z ? r : z * .5f;

            //set the radius.
            foreach(Vector3 vert in mesh.vertices)
            {
                r=Vector3.Distance(vert, origin) > r ? Vector3.Distance(vert, origin) : r;
            }
            bounds.Add(new Vector4(origin.x,origin.y,origin.z, r));
        }
    }
}
