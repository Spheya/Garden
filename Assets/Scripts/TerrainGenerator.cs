using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
[ExecuteAlways]
public class TerrainGenerator : MonoBehaviour
{
    private void OnEnable()
    {
        List<Vector3> positions = new List<Vector3>();
        List<Vector3> normals = new List<Vector3>();
        List<int> indices = new List<int>();
        List<int> indices2 = new List<int>();

        positions.AddRange(new[] {
            // Bottom Plane
            new Vector3(-1.0f, 0.0f, -1.0f),
            new Vector3(-1.0f, 0.0f, 1.0f),
            new Vector3(1.0f, 0.0f, -1.0f),
            new Vector3(1.0f, 0.0f, 1.0f),

            // Left Plane
            new Vector3(1.0f, 0.0f, -1.0f),
            new Vector3(1.0f, 0.0f, 1.0f),
            new Vector3(1.0f, 1.0f, -1.0f),
            new Vector3(1.0f, 1.0f, 1.0f),

            // Right Plane
            new Vector3(-1.0f, 0.0f, -1.0f),
            new Vector3(-1.0f, 0.0f, 1.0f),
            new Vector3(-1.0f, 1.0f, -1.0f),
            new Vector3(-1.0f, 1.0f, 1.0f),

            // Front Plane
            new Vector3(-1.0f, 0.0f, 1.0f),
            new Vector3(-1.0f, 1.0f, 1.0f),
            new Vector3(1.0f, 0.0f, 1.0f),
            new Vector3(1.0f, 1.0f, 1.0f),

            // Right Plane
            new Vector3(-1.0f, 0.0f, -1.0f),
            new Vector3(-1.0f, 1.0f, -1.0f),
            new Vector3(1.0f, 0.0f, -1.0f),
            new Vector3(1.0f, 1.0f, -1.0f),
        });

        normals.AddRange(new[] {
            // Bottom Plane
            new Vector3(0.0f, 1.0f, 0.0f),
            new Vector3(0.0f, 1.0f, 0.0f),
            new Vector3(0.0f, 1.0f, 0.0f),
            new Vector3(0.0f, 1.0f, 0.0f),

            // Left Plane
            new Vector3(1.0f, 0.0f, 0.0f),
            new Vector3(1.0f, 0.0f, 0.0f),
            new Vector3(1.0f, 0.0f, 0.0f),
            new Vector3(1.0f, 0.0f, 0.0f),

            // Right Plane
            new Vector3(-1.0f, 0.0f, 0.0f),
            new Vector3(-1.0f, 0.0f, 0.0f),
            new Vector3(-1.0f, 0.0f, 0.0f),
            new Vector3(-1.0f, 0.0f, 0.0f),

            // Front Plane
            new Vector3(0.0f, 0.0f, 1.0f),
            new Vector3(0.0f, 0.0f, 1.0f),
            new Vector3(0.0f, 0.0f, 1.0f),
            new Vector3(0.0f, 0.0f, 1.0f),

            // Back Plane
            new Vector3(0.0f, 0.0f, -1.0f),
            new Vector3(0.0f, 0.0f, -1.0f),
            new Vector3(0.0f, 0.0f, -1.0f),
            new Vector3(0.0f, 0.0f, -1.0f),
        });

        indices.AddRange(new[]{
            0, 1, 2, 2, 1, 3,
        });

        indices2.AddRange(new[] {
            4, 6, 5, 5, 6, 7,
            8, 9, 10, 10, 9, 11,
            12, 14, 13, 13, 14, 15,
            16, 17, 18, 18, 17, 19,
        });

        Mesh mesh = new Mesh();
        mesh.SetVertices(positions);
        mesh.SetNormals(normals);
        mesh.subMeshCount = 2;
        mesh.SetTriangles(indices.ToArray(), 1);
        mesh.SetTriangles(indices2.ToArray(), 0); 
        
        GetComponent<MeshFilter>().sharedMesh = mesh;
    }
}
