'use client';

import { Suspense, useEffect, useRef, useState } from 'react';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import * as THREE from 'three';

import vertexShader from '@/shaders/common/vertex.glsl';
import fragmentShader from './fragment.glsl';

const Test = ({ dpr, volumeData, headData, abdData }: { dpr: number; volumeData: Uint8Array | null; headData : Uint8Array | null ; abdData : Uint8Array | null }) => {
  const { viewport } = useThree();

  const tex = new THREE.Data3DTexture(volumeData, 256, 256, 256);
  tex.format = THREE.RedFormat;
  // tex.type = THREE.FloatType;
  tex.minFilter = THREE.LinearFilter;
  tex.magFilter = THREE.LinearFilter;
  tex.wrapS = THREE.ClampToEdgeWrapping;
  tex.wrapT = THREE.ClampToEdgeWrapping;
  tex.wrapR = THREE.ClampToEdgeWrapping;
  tex.needsUpdate = true;


  const texHead = new THREE.Data3DTexture(headData, 128, 256, 256);
  texHead.format = THREE.RedFormat;
  texHead.minFilter = THREE.LinearFilter;
  texHead.magFilter = THREE.LinearFilter;
  texHead.wrapS = THREE.ClampToEdgeWrapping;
  texHead.wrapT = THREE.ClampToEdgeWrapping;
  texHead.wrapR = THREE.ClampToEdgeWrapping;
  texHead.needsUpdate = true;


  // const texAbd = new THREE.Data3DTexture(abdData, 512, 512, 174);
  // texAbd.format = THREE.RedFormat;
  // texAbd.minFilter = THREE.LinearFilter;
  // texAbd.magFilter = THREE.LinearFilter;
  // texAbd.wrapS = THREE.ClampToEdgeWrapping;
  // texAbd.wrapT = THREE.ClampToEdgeWrapping;
  // texAbd.wrapR = THREE.ClampToEdgeWrapping;
  // texAbd.needsUpdate = true;


  const uniforms = useRef({
    iTime: { value: 0 },
    iResolution: {
      value: new THREE.Vector2(window.innerWidth * dpr, window.innerHeight * dpr),
    },
    iVolume: {
      value: tex,
    },
    iVolumeHead: {
      value: texHead,
    },
    iVolumeAbd: {
      value: null,
    }
  }).current;

  useFrame((_, delta) => {
    uniforms.iTime.value += delta;
    uniforms.iResolution.value.set(window.innerWidth * dpr, window.innerHeight * dpr);
  });

  return (
    <mesh scale={[viewport.width, viewport.height, 1]}>
      <planeGeometry args={[1, 1]} />
      <shaderMaterial
        fragmentShader={fragmentShader}
        vertexShader={vertexShader}
        uniforms={uniforms}
      />
    </mesh>
  );
};

export default function TestPage() {
  const [volumeData, setVolumeData] = useState<Uint8Array | null>(null);
  const [headData, setHeadData] = useState<Uint8Array | null>(null);
  // const [abdData, setAbdData] = useState<Uint8Array | null>(null);

  useEffect(() => {
    const loadVolume = async (path: string, setter: React.Dispatch<React.SetStateAction<Uint8Array | null>>) => {
      try {
        const response = await fetch(path);
        if (!response.ok) throw new Error(`Failed to fetch: ${response.statusText}`);
        const data = await response.arrayBuffer();
        setter(new Uint8Array(data));
      } catch (error) {
        console.error(error);
      }
    };

    loadVolume('/foot_256x256x256_uint8.raw', setVolumeData);
    loadVolume('/vis_male_128x256x256_uint8.raw', setHeadData);
    // loadVolume('/prone_512x512x463_uint16.raw', setAbdData);
  }, []);

  const dpr = 1;
  return (
    <>
      <Canvas
        orthographic
        dpr={dpr}
        camera={{ position: [0.0, 0.0, 1000.0] }}
        style={{
          zIndex: -1,
          position: 'fixed',
          top: 0,
          left: 0,
          width: '100vw',
          height: '100vh',
        }}
      >
        <Suspense fallback={null}>
          {volumeData && headData && <Test dpr={dpr} volumeData={volumeData} headData={headData}/>}
        </Suspense>
      </Canvas>
      {/* <div className="absolute top-16">
        <input type="file" onChange={handleVolumeFileUpload} />
      </div> */}
    </>
  );
}
