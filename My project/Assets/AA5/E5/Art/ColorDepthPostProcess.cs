using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(ColorDepthRenderer), PostProcessEvent.BeforeStack, "Custom/ColorDepth")]
public sealed class ColorDepth : PostProcessEffectSettings
{
    [Range(0f, 1f), Tooltip("Grayscale effect intensity.")]
    public FloatParameter blend = new FloatParameter { value = 0.5f };
    public Vector3Parameter position = new Vector3Parameter { value = new Vector3(0,0,0) };
}
public sealed class ColorDepthRenderer : PostProcessEffectRenderer<ColorDepth>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/ColorDepth"));
        sheet.properties.SetFloat("_Blend", settings.blend);
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}