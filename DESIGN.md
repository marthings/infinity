---
version: alpha
name: Infinity
description: A quiet personal library for links, files, images, and inspiration.
colors:
  surface: "#ffffff"
  surface-container: "#f5f5f5"
  surface-container-high: "#ebebeb"
  surface-variant: "#f5f5f5"
  surface-raised: "#ffffff"
  on-surface: "#171717"
  on-surface-variant: "#5f5f5f"
  outline: "#d7d7d7"
  outline-strong: "#9c9c9c"
  primary: "#171717"
  on-primary: "#ffffff"
  error: "#b42318"
  on-error: "#ffffff"
  focus: "#171717"
colors_dark:
  surface: "#181818"
  surface-container: "#242424"
  surface-container-high: "#2c2c2c"
  surface-variant: "#242424"
  surface-raised: "#1f1f1f"
  on-surface: "#f4f4f4"
  on-surface-variant: "#b8b8b8"
  outline: "#454545"
  outline-strong: "#787878"
  primary: "#f4f4f4"
  on-primary: "#181818"
  error: "#ffb4ab"
  on-error: "#690005"
  focus: "#f4f4f4"
typography:
  display: { fontFamily: "system-ui", fontSize: 32px, fontWeight: 700, lineHeight: 40px }
  heading: { fontFamily: "system-ui", fontSize: 24px, fontWeight: 700, lineHeight: 32px }
  title: { fontFamily: "system-ui", fontSize: 18px, fontWeight: 650, lineHeight: 24px }
  body: { fontFamily: "system-ui", fontSize: 16px, fontWeight: 400, lineHeight: 24px }
  label: { fontFamily: "system-ui", fontSize: 14px, fontWeight: 600, lineHeight: 20px }
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
rounded:
  none: 0px
  sm: 8px
  md: 16px
  full: 9999px
lines:
  text-decoration: 1px
  focus: 2px
---

# Infinity

## Overview

Infinity is a private, work-focused library. The interface is restrained so saved material remains the primary visual signal. It should feel direct on web and native shells, not promotional or decorative.

## Colors

The product uses black and white as its primary contrast pair. Neutral grays separate surfaces and communicate hierarchy; red is reserved for destructive or error feedback. Dark mode is a true neutral inversion with softened black surfaces rather than pure black.

## Typography

Use the platform system sans-serif stack for speed, legibility, and a native-adjacent feel. Body text is never smaller than 16px in inputs. Weight and spacing establish hierarchy; do not use compressed tracking or oversized display type in application views.

## Layout

Spacing follows a 4px base and 8px layout rhythm. Content is constrained for readable line lengths, with mobile-first padding. Hierarchy comes from whitespace, alignment, typography, and restrained surface changes rather than framed regions or dividers. Tab-root pages do not repeat their native navigation title in native content; browser headings and subview headings remain semantic.

## Elevation & Depth

The default interface is flat and borderless. Use whitespace and subtle surface changes to separate durable regions. Avoid shadows except for transient overlays introduced later.

## Shapes

Page content is unframed. Inputs, buttons, and compact controls use a 16px radius by default. Rounded pills are reserved for compact status or segmented controls, not general layout.

## Components

Forms use clear labels, full-width controls on `surface-container`, visible keyboard focus, and direct primary actions. Grouped form regions use `surface-container-high` so their nested controls remain perceptible. Capture rows are separated by whitespace rather than dividers or cards. Navigation links expose their current or keyboard state through color and focus treatment; focus outlines are the sole persistent outlines in the interface.

## Do's and Don'ts

Do use semantic color roles and spacing tokens. Do preserve user zoom and system appearance settings. Do keep captured media and information more visually prominent than interface chrome.

Do not introduce a component library, downloaded font, decorative gradient, color accent for routine controls, or nested card layout.
