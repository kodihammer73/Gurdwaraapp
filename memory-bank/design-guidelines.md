# Gurdwara App - Design Guidelines

## Brand Identity

### Philosophy
Modern, minimalist, elegant design for young Sikh community members. Clean interfaces with intentional whitespace, avoiding clutter while maintaining spiritual reverence.

### Target Audience
- Age: 16-45 years old
- Tech-savvy Sikh community members
- Users seeking quick access to information
- Mobile-first users with varying connection speeds

---

## Color System

### Primary Colors
- **Saffron** `#E8A838` - Main brand color (buttons, highlights)
- **Saffron Light** `#F5D084` - Hover states, secondary highlights
- **Saffron Dark** `#C5851E` - Active states, emphasis

### Secondary Colors
- **Navy** `#1B365D` - Text, headers, navigation
- **Navy Light** `#2A4B7C` - Secondary text, borders

### Accent Colors
- **Gold** `#C5A028` - Premium accents, special elements
- **Gold Light** `#E0C060` - Subtle accents

### Neutral Palette
- **Cream** `#FAF8F5` - Primary background
- **White** `#FFFFFF` - Cards, elevated surfaces
- **Gray 200** `#E2DFD8` - Borders, dividers
- **Gray 600** `#5C5854` - Secondary text
- **Gray 900** `#1A1817` - Primary text

### Semantic Colors
- **Success**: `#2E7D32` (Green)
- **Warning**: `#F57C00` (Orange)
- **Error**: `#C62828` (Red)
- **Info**: `#1976D2` (Blue)

### Dark Mode
Automatically inverts colors while maintaining contrast ratio of 4.5:1 for accessibility.

---

## Typography

### Font Families
- **Headings**: 'Playfair Display' (elegant serif)
  - Weights: 400 (Regular), 600 (SemiBold), 700 (Bold)
  - Usage: Page titles, section headers, card titles

- **Body**: 'Inter' (modern sans-serif)
  - Weights: 300 (Light), 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)
  - Usage: Body text, labels, buttons

### Font Sizes
```
Display: 48px (3rem)      - Page hero title
Headline: 32px (2rem)     - Section titles
Title: 24px (1.5rem)      - Card titles, headers
Subtitle: 20px (1.25rem)  - Secondary headers
Body Large: 16px (1rem)   - Main body text
Body: 14px (0.875rem)     - Secondary text
Caption: 12px (0.75rem)   - Labels, timestamps
```

### Line Heights
- Headings: 1.2
- Body: 1.7
- Small text: 1.5

---

## Spacing System

```
xs:   4px   (0.25rem)    - Tight spacing
sm:   8px   (0.5rem)     - Small gaps
md:   16px  (1rem)       - Standard spacing
lg:   24px  (1.5rem)     - Large spacing
xl:   32px  (2rem)       - Extra large spacing
2xl:  48px  (3rem)       - Double spacing
3xl:  64px  (4rem)       - Triple spacing
4xl:  96px  (6rem)       - Quadruple spacing
```

**Usage**:
- Padding: Inside containers and cards
- Margin: Between sections and elements
- Gap: Between grid/flex items

---

## Border Radius

```
sm:   6px       - Small elements (chips, small buttons)
md:   12px      - Cards, medium containers
lg:   20px      - Large containers, modals
xl:   28px      - Extra large elements
full: 9999px    - Pills, fully rounded (avatars, badges)
```

---

## Shadows & Elevation

### Shadow Levels
- **None**: `0` - Flat design elements
- **Small**: `0 1px 3px rgba(0,0,0,0.06)` - Subtle elevation
- **Medium**: `0 4px 12px rgba(0,0,0,0.08)` - Cards, dropdowns
- **Large**: `0 8px 30px rgba(0,0,0,0.12)` - Modals, significant elevation
- **XL**: `0 20px 60px rgba(0,0,0,0.15)` - Floating action buttons, overlays

### Usage
- **No shadow**: Body text, backgrounds
- **Small shadow**: Hover states, subtle depth
- **Medium shadow**: Cards, buttons (elevated)
- **Large shadow**: Modals, dialogs
- **XL shadow**: FAB, important overlays

---

## Component Guidelines

### Buttons

**Primary Button**
- Background: Saffron (`#E8A838`)
- Text: Navy (`#1B365D`)
- Padding: 12px 24px
- Border Radius: 12px
- Font Weight: 600
- Minimum height: 48px (for touch accessibility)

**Secondary Button**
- Background: Transparent
- Border: 2px Navy
- Text: Navy
- Same padding & radius as primary

**Tertiary Button**
- Background: Gray 100
- Text: Gray 900
- No border
- Same sizing

**Disabled State**
- Opacity: 50%
- Cursor: Not allowed

**Hover State**
- Primary: Background darkens to Saffron Dark
- Secondary: Light background highlight

### Cards

- Background: White (`#FFFFFF`)
- Border Radius: 12-20px
- Shadow: Medium
- Padding: 16px-24px
- Margin: 16px between cards
- Minimal borders (use shadows for depth)

### Input Fields

- Border: 1px Gray 200
- Border Radius: 12px
- Padding: 12px 16px
- Focus: Border color changes to Saffron
- Font: Inter 16px
- Minimum height: 48px

### Navigation

- Bottom navigation preferred for mobile
- Clear icons with labels
- Active tab: Saffron background/text
- Inactive tab: Gray text
- No more than 5 tabs

### Cards for Lists

- Minimal visual hierarchy
- Use whitespace effectively
- Thumbnail images optional (not mandatory)
- Subtitle: Secondary gray text
- Consistent padding throughout

---

## Animations & Transitions

### Duration
- **Fast**: 150ms - Quick interactions (hover, active states)
- **Base**: 250ms - Standard transitions (page changes, modal opens)
- **Slow**: 400ms - Delightful animations (hero transitions, onboarding)

### Easing
- **Standard**: `ease` - Default transitions
- **Ease In**: Opening/revealing elements
- **Ease Out**: Closing/hiding elements

### Best Practices
- Micro-animations for feedback (button presses)
- Smooth page transitions
- Avoid excessive animations (keep performance first)
- Consistent animation language across app

---

## Accessibility

### WCAG 2.1 AA Compliance
- Contrast ratio: Minimum 4.5:1 for text
- Minimum touch target: 48x48px
- Focus indicators: Always visible
- Alt text: All images have descriptions

### Color Blindness
- Don't rely solely on color
- Use icons + color for status
- High contrast primary actions

### Text Sizing
- Support dynamic text sizing (100%-200%)
- Readable on small screens
- Line length: Max 75 characters

---

## Layout Principles

### Grid System
- 12-column grid for consistency
- Responsive breakpoints:
  - Mobile: < 576px (single column)
  - Tablet: 576px - 768px (2 columns)
  - Desktop: 768px+ (3-4 columns)

### Safe Areas
- 16px padding on mobile edges
- 24px padding on larger screens
- Account for notches/safe areas on modern devices

### Whitespace
- Generous use of whitespace
- Min 16px between sections
- Visual breathing room intentional

---

## Dark Mode

- Automatically supported
- Colors invert appropriately
- Maintains contrast requirements
- No additional code needed (Material 3 handles it)
- Test on actual OLED screens

---

## Image Guidelines

### Sizes
- Hero images: Full width, 250-300px height
- Card images: 200x150px (16:9 ratio)
- Thumbnails: 64x64px or 80x80px
- Avatars: 40x40px (minimum)

### Optimization
- Use WebP format where supported
- Progressive JPEG fallbacks
- Lazy load below-fold images
- Compress all images before uploading

### Content
- Authentic photos of Gurdwara and community
- Diverse representation
- Spiritual but approachable tone
- High quality, well-lit images

---

## Content Tone

- **Respectful**: Honor Sikh traditions
- **Modern**: Contemporary language and approach
- **Inclusive**: Welcoming to all
- **Clear**: Avoid jargon where possible
- **Concise**: Respect user's time

---

## Mobile-First Design

1. Design for smallest screens first
2. Progressive enhancement for larger screens
3. Touch-friendly spacing (minimum 48px tap targets)
4. Readable on 320px width devices
5. Fast performance prioritized
6. Minimal data usage
7. Offline functionality where possible

---

## Consistency Checklist

- [ ] Color usage matches palette
- [ ] Font sizes follow scale
- [ ] Spacing aligns to 4px grid
- [ ] Border radius consistent (md=12px for most)
- [ ] Shadows used appropriately
- [ ] Buttons accessible (min 48x48px)
- [ ] Text contrast meets WCAG AA
- [ ] Dark mode tested
- [ ] Responsive on all breakpoints
- [ ] Animations are purposeful