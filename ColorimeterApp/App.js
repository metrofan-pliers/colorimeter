import React, { useState, useEffect } from 'react';
import { Text, View, StyleSheet } from 'react-native';

const SERVER_URL = 'http://141.8.192.25:8000';

function detectColorName(r, g, b, h, s, v) {
  const sNorm = s / 100;
  const vNorm = v / 100;

  if (vNorm < 0.10) return 'black';

  if (sNorm < 0.18) {
    if (vNorm > 0.80) return 'white';
    if (vNorm > 0.25) return 'gray';
    return 'black';
  }

  if (sNorm < 0.4 && vNorm > 0.4) {
    if (h >= 20 && h < 50) return 'beige';
    if (h >= 320 || h < 20) return 'pink';
  }

  if (h < 40 && vNorm < 0.20 && sNorm > 0.25) return 'brown';
  if (h >= 30 && h < 55) return 'yellow';
  if (h >= 5 && h < 25 && vNorm >= 0.35) return 'orange';
  
  if (h >= 0 && h < 15) return 'red';
  if (h >= 345 && h < 360) return 'red';
  if (h >= 15 && h < 45) return 'orange';
  if (h >= 45 && h < 75) return 'yellow';
  if (h >= 75 && h < 150) return 'green';
  if (h >= 150 && h < 195) return 'cyan';
  if (h >= 195 && h < 255) return 'blue';
  if (h >= 255 && h < 285) return 'purple';
  if (h >= 285 && h < 345) return 'magenta';

  return 'unknown';
}

function rgbToHsv(r, g, b) {
  r /= 255;
  g /= 255;
  b /= 255;

  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const diff = max - min;

  let h = 0;
  const s = max === 0 ? 0 : diff / max;
  const v = max;

  if (diff !== 0) {
    if (max === r) {
      h = 60 * (((g - b) / diff) % 6);
    } else if (max === g) {
      h = 60 * (((b - r) / diff) + 2);
    } else {
      h = 60 * (((r - g) / diff) + 4);
    }
  }

  if (h < 0) h += 360;

  return {
    h: Math.round(h),
    s: Math.round(s * 100),
    v: Math.round(v * 100)
  };
}

export default function App() {
  const [color, setColor] = useState({
    r: 0,
    g: 0,
    b: 0,
    hex: '#000000',
    colorName: 'Loading...'
  });
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchColor = async () => {
    try {
      const response = await fetch(`${SERVER_URL}/color`);
      const data = await response.json();
      
      const hsv = data.hsv || rgbToHsv(data.r, data.g, data.b);
      const colorName = data.colorName || detectColorName(data.r, data.g, data.b, hsv.h, hsv.s, hsv.v);
      
      setColor({
        r: data.r,
        g: data.g,
        b: data.b,
        hex: data.hex,
        colorName: colorName
      });
      setError(null);
      setLoading(false);
    } catch (err) {
      setError('No connection');
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchColor();
    const interval = setInterval(fetchColor, 2000);
    return () => clearInterval(interval);
  }, []);

  return (
    <View style={styles.container}>
      {loading ? (
        <Text style={styles.text}>Loading...</Text>
      ) : error ? (
        <Text style={styles.errorText}>{error}</Text>
      ) : (
        <>
          <Text style={styles.colorName}>{color.colorName}</Text>
          <Text style={styles.hexText}>{color.hex}</Text>
          <Text style={styles.rgbText}>
            RGB({color.r}, {color.g}, {color.b})
          </Text>
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
    justifyContent: 'center',
    alignItems: 'center',
  },
  text: {
    color: '#888888',
    fontSize: 18,
  },
  errorText: {
    color: '#ff4444',
    fontSize: 18,
  },
  colorName: {
    color: '#ffffff',
    fontSize: 32,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  hexText: {
    color: '#ffffff',
    fontSize: 24,
    marginBottom: 10,
  },
  rgbText: {
    color: '#aaaaaa',
    fontSize: 18,
  },
});
