using UnityEngine;

// -- Recreates mesh collider based on the new GPU (shader) render texture 

[RequireComponent(typeof(MeshFilter), typeof(MeshCollider))]
public class SnowColliderUpdater : MonoBehaviour
{
    public RenderTexture splatmap;
    public float displacement = 0.3f;

    private Mesh _runtimeMesh;
    private Texture2D _splatCPU;
    private Vector3[] _originalVertices;
    private Vector3[] _normals;
    private Vector2[] _uvs;

    void Start()
    {
        Mesh original = GetComponent<MeshFilter>().mesh;
        _runtimeMesh = Instantiate(original);

        _originalVertices = _runtimeMesh.vertices;
        _normals = _runtimeMesh.normals;
        _uvs = _runtimeMesh.uv;
        _splatCPU = new Texture2D(splatmap.width, splatmap.height, TextureFormat.RGBAFloat, false);

        GetComponent<MeshFilter>().mesh = _runtimeMesh;
        GetComponent<MeshCollider>().sharedMesh = _runtimeMesh;

    }

    void Update()
    {
        UpdateColliderFromSplat();
    }

    public void UpdateColliderFromSplat()
    {
        RenderTexture.active = splatmap;
        _splatCPU.ReadPixels(new Rect(0, 0, splatmap.width, splatmap.height), 0, 0);
        _splatCPU.Apply();
        RenderTexture.active = null;

        Vector3[] deformed = new Vector3[_originalVertices.Length];

        for (int i = 0; i < deformed.Length; i++)
        {
            Vector3 v0 = _originalVertices[i];
            Vector3 n0 = _normals[i];
            Vector2 uv = _uvs[i];

            float splatR = _splatCPU.GetPixelBilinear(uv.x, uv.y).r;
            float offset = displacement - (displacement * splatR); 
            deformed[i] = v0 + n0 * offset;
        }

        _runtimeMesh.vertices = deformed;
        _runtimeMesh.RecalculateNormals();
        _runtimeMesh.RecalculateBounds();

        MeshCollider col = GetComponent<MeshCollider>();
        col.sharedMesh = null;
        col.sharedMesh = _runtimeMesh;
    }
}
