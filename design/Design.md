---
name: Brew & Bloom
colors:
  surface: '#fbf9f5'
  surface-dim: '#dbdad6'
  surface-bright: '#fbf9f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3ef'
  surface-container: '#efeeea'
  surface-container-high: '#eae8e4'
  surface-container-highest: '#e4e2de'
  on-surface: '#1b1c1a'
  on-surface-variant: '#414941'
  inverse-surface: '#30312e'
  inverse-on-surface: '#f2f0ed'
  outline: '#727971'
  outline-variant: '#c1c9bf'
  surface-tint: '#3c6846'
  primary: '#3a6544'
  on-primary: '#ffffff'
  primary-container: '#527e5b'
  on-primary-container: '#f6fff3'
  inverse-primary: '#a2d2a9'
  secondary: '#725a43'
  on-secondary: '#ffffff'
  secondary-container: '#ffdcbf'
  on-secondary-container: '#795f49'
  tertiary: '#7b542b'
  on-tertiary: '#ffffff'
  tertiary-container: '#966c41'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#bdefc4'
  primary-fixed-dim: '#a2d2a9'
  on-primary-fixed: '#00210c'
  on-primary-fixed-variant: '#244f30'
  secondary-fixed: '#ffdcbf'
  secondary-fixed-dim: '#e1c1a5'
  on-secondary-fixed: '#291806'
  on-secondary-fixed-variant: '#59422d'
  tertiary-fixed: '#ffdcbd'
  tertiary-fixed-dim: '#f0bd8b'
  on-tertiary-fixed: '#2c1600'
  on-tertiary-fixed-variant: '#623f18'
  background: '#fbf9f5'
  on-background: '#1b1c1a'
  surface-variant: '#e4e2de'
typography:
  display-lg:
    fontFamily: Public Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Public Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  stat-xl:
    fontFamily: Public Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  body-lg:
    fontFamily: Public Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Public Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  label-sm:
    fontFamily: Public Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  margin: 20px
  gutter: 16px
---

## Brand & Style

The brand personality is centered around the concept of a "daily ritual"—transforming the simple act of tracking caffeine and tea intake into a moment of calm and mindfulness. The target audience includes urban professionals, students, and wellness enthusiasts who appreciate the craft of a well-made beverage.

The visual style combines **Minimalism** with **Tactile** warmth. It avoids the clinical coldness of typical utility apps by using organic shapes and a palette inspired by nature and cafe culture. The emotional response should be one of comfort and reliability, similar to the feeling of holding a warm mug in a quiet space. The design system utilizes high-quality whitespace and soft transitions to ensure the user feels unhurried and focused.

## Colors

The color palette is derived from the organic tones of ingredients. 
- **Primary (Matcha Green):** Used exclusively for primary actions, progress indicators, and success states. It provides a refreshing contrast to the warmer tones.
- **Secondary (Latte Brown):** Used for navigation elements, secondary buttons, and iconography.
- **Neutral (Creamy White):** The foundation of the UI, used for backgrounds and surfaces to maintain an airy, clean feel.
- **Text (Espresso):** A deep, warm brown used instead of pure black to maintain softness while ensuring high legibility.

Avoid using pure grays; all neutrals and shadows should have a slight warm tint to maintain the "cozy" atmosphere.

## Typography

This design system uses **Public Sans** for its exceptional clarity and friendly, open letterforms. 

A specific hierarchy is established for "Stats" (e.g., caffeine count, water intake). These use the `stat-xl` style with tighter letter spacing and bold weights to provide an immediate visual anchor on the dashboard. Body text is set with generous line height to ensure a relaxed reading experience. Labels use a slightly increased letter spacing and semi-bold weight for quick scanning in dense data areas.

## Layout & Spacing

The layout follows a **fluid grid** model with safe margins specifically tuned for mobile ergonomics. 
- **Rhythm:** An 8px base unit drives all spacing decisions.
- **Margins:** A standard 20px side margin ensures content does not feel cramped against the screen edges.
- **Grouping:** Use the `lg` (40px) spacing to separate major content blocks (e.g., daily total vs. recent history) to provide visual "breathing room."

Content containers should use dynamic padding that scales with the screen size, prioritizing a centered, single-column view for the primary tracking dashboard.

## Elevation & Depth

Hierarchy is established using **Ambient Shadows** and **Tonal Layers**. 
- **Shadows:** Use extra-diffused, low-opacity shadows. The shadow color must be a dark brown tint (`#3E2F28` at 8-12% opacity) rather than black to keep the warmth.
- **Tiers:** 
  - **Level 0 (Background):** Creamy White.
  - **Level 1 (Cards/Containers):** Pure White with a subtle shadow.
  - **Level 2 (Modals/Floating Actions):** Pure White with a deeper, more diffused shadow to imply closer proximity to the user.
- **Transitions:** Elements should feel like they are resting on a soft surface. Avoid sharp, high-contrast borders; favor depth through shadow and subtle color shifts.

## Shapes

The shape language is "Cozy Organic." 
Standard elements like input fields and buttons utilize a **0.5rem (8px)** corner radius. Large containers and cards use a more pronounced **1.5rem (24px)** radius to reinforce the soft, approachable feel. 

Special decorative elements or beverage "chips" may use asymmetric rounding or circular "blob" shapes to mimic steam or liquid splashes, adding a playful, hand-crafted touch to the minimalist interface.

## Components

- **Buttons:** Primary buttons are Matcha Green with white text, featuring a subtle "press" animation that reduces shadow depth. Secondary buttons use a Latte Brown outline or ghost style.
- **Cards:** These are the primary data containers. They must have a white background and the `rounded-xl` radius. Content inside should be padded at `md` (24px).
- **Icons:** Use line-art style with a consistent 2pt stroke width. End-caps should be rounded. Add a slight "imperfect" curve to select icons to give them a friendly, hand-drawn character.
- **Chips:** Used for beverage types (e.g., "Oat Milk," "Espresso"). These are small, pill-shaped elements with a light tan background and brown text.
- **Progress Rings:** For tracking daily limits, use soft, thick strokes in Matcha Green with a lighter, desaturated green as the track color.
- **Input Fields:** Use a subtle Cream-tinted background with a soft Latte Brown border that thickens slightly on focus.