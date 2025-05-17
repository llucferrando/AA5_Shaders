using UnityEngine;

public class DrawWithSphereVolumeContact : MonoBehaviour
{
    public Shader _drawShader;
    public Transform _sphere;
    public int gridSteps = 5;
    public float _brushSize = 20;
    public float _brushStrength = 1f;

    private RenderTexture _splatmap;
    private Material _drawMaterial, _targetMaterial;

    void Start()
    {
        _drawMaterial = new Material(_drawShader);
        _drawMaterial.SetVector("_Color", Color.red);

        _targetMaterial = GetComponent<MeshRenderer>().material;
        _splatmap = new RenderTexture(128, 128, 0, RenderTextureFormat.ARGBFloat);
        _targetMaterial.SetTexture("_Splat", _splatmap);
    }

    void Update()
    {
        if (_sphere == null) return;

        float radius = _sphere.localScale.x * 0.5f;
        Vector3 center = _sphere.position;

        // Verificamos que la esfera realmente intersecta con el terreno
        if (!Physics.CheckSphere(center, radius)) return;

        for (int x = -gridSteps; x <= gridSteps; x++)
        {
            for (int z = -gridSteps; z <= gridSteps; z++)
            {
                Vector2 offset = new Vector2(x, z) / gridSteps * radius;
                if (offset.magnitude > radius) continue; // fuera de la esfera

                Vector3 origin = center + new Vector3(offset.x, 0.2f, offset.y);

                if (Physics.Raycast(origin, Vector3.down, out RaycastHit hit, radius + 0.3f))
                {
                    if (hit.collider.gameObject == gameObject)
                    {
                        float verticalDistance = center.y - hit.point.y;
                        if (verticalDistance < radius) // aseguramos contacto
                        {
                            Vector2 uv = hit.textureCoord;
                            _drawMaterial.SetVector("_Coordinate", new Vector4(uv.x, uv.y, 0, 0));
                            float diameter = _sphere.localScale.x; // Escala uniforme
                            _drawMaterial.SetFloat("_Size", diameter);

                            _drawMaterial.SetFloat("_Strenght", _brushStrength);

                            RenderTexture temp = RenderTexture.GetTemporary(_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
                            Graphics.Blit(_splatmap, temp);
                            Graphics.Blit(temp, _splatmap, _drawMaterial);
                            RenderTexture.ReleaseTemporary(temp);
                        }
                    }
                }
            }
        }
    }

    private void OnGUI()
    {
        GUI.DrawTexture(new Rect(0, 0, 128, 128), _splatmap, ScaleMode.ScaleToFit, false, 1);
    }
}
