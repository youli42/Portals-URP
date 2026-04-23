using System.Collections.Generic;
using UnityEngine;

public class PortalTraveller : MonoBehaviour
{

    public GameObject graphicsObject; // 物体的原始几何模型（用于渲染的部分）
    public GameObject graphicsClone { get; set; } // 在出口处生成的“替身”模型，确保物体穿门时两边都有画面。
    public Vector3 previousOffsetFromPortal { get; set; } // 记录上一帧物体相对于传送门平面的偏移量，用于判断物体是否真正“跨越”了平面。

    public Material[] originalMaterials { get; set; } // 原始物体的所有材质球引用，用于动态设置 Shader 参数（如裁剪面）。
    public Material[] cloneMaterials { get; set; } // 替身物体的所有材质球引用。

    public virtual void Teleport(Transform fromPortal, Transform toPortal, Vector3 pos, Quaternion rot)
    {
        transform.position = pos;
        transform.rotation = rot;
    }

    // 首次触碰传送门时被调用
    public virtual void EnterPortalThreshold()
    {
        if (graphicsClone == null)
        {
            graphicsClone = Instantiate(graphicsObject); // 实例化正在穿过的物体
            graphicsClone.transform.parent = graphicsObject.transform.parent;
            graphicsClone.transform.localScale = graphicsObject.transform.localScale;
            originalMaterials = GetMaterials(graphicsObject);
            cloneMaterials = GetMaterials(graphicsClone);
        }
        else
        {
            graphicsClone.SetActive(true);
        }
    }

    // 仅在不再触碰传送门时调用一次（传送时除外）
    public virtual void ExitPortalThreshold()
    {
        graphicsClone.SetActive(false);
        // 禁用切片功能
        for (int i = 0; i < originalMaterials.Length; i++)
        {
            originalMaterials[i].SetVector("sliceNormal", Vector3.zero);
        }
    }

    // 设置切片偏移量
    public void SetSliceOffsetDst(float dst, bool clone)
    {
        for (int i = 0; i < originalMaterials.Length; i++)
        {
            if (clone)
            {
                cloneMaterials[i].SetFloat("sliceOffsetDst", dst);
            }
            else
            {
                originalMaterials[i].SetFloat("sliceOffsetDst", dst);
            }

        }
    }

    Material[] GetMaterials(GameObject g)
    {
        var renderers = g.GetComponentsInChildren<MeshRenderer>();
        var matList = new List<Material>();
        foreach (var renderer in renderers)
        {
            foreach (var mat in renderer.materials)
            {
                matList.Add(mat);
            }
        }
        return matList.ToArray();
    }
}