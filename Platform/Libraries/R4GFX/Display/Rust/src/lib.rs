#![no_std]
//! R4GFX-owned signed output geometry. This is the Rust consumer of the
//! current topology.zig policy, independent of any Desktop application.
//! Layout admission is geometry, not a hardware or atomic-commit receipt.
pub const CAPACITY: usize = 8;
pub const SCALE_UNIT: u32 = 120;
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Invalid,
    Bounds,
    Empty,
    Duplicate,
    Overlap,
    Clone,
    Primary,
    Capacity,
}
pub type Result<T> = core::result::Result<T, Error>;
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Point {
    pub x: i32,
    pub y: i32,
}
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Rect {
    pub x: i32,
    pub y: i32,
    pub w: u32,
    pub h: u32,
}
impl Rect {
    pub fn right(self) -> i64 {
        i64::from(self.x) + i64::from(self.w)
    }
    pub fn bottom(self) -> i64 {
        i64::from(self.y) + i64::from(self.h)
    }
    pub fn valid(self) -> bool {
        self.w != 0
            && self.h != 0
            && self.w <= i32::MAX as u32
            && self.h <= i32::MAX as u32
            && self.right() <= i64::from(i32::MAX)
            && self.bottom() <= i64::from(i32::MAX)
    }
    pub fn contains(self, p: Point) -> bool {
        p.x >= self.x
            && p.y >= self.y
            && i64::from(p.x) < self.right()
            && i64::from(p.y) < self.bottom()
    }
    pub fn intersection(self, other: Self) -> Option<Self> {
        let (x, y) = (self.x.max(other.x), self.y.max(other.y));
        let (right, bottom) = (
            self.right().min(other.right()),
            self.bottom().min(other.bottom()),
        );
        if right <= i64::from(x) || bottom <= i64::from(y) {
            return None;
        }
        Some(Self {
            x,
            y,
            w: (right - i64::from(x)) as u32,
            h: (bottom - i64::from(y)) as u32,
        })
    }
    pub fn project(self, p: Point) -> Point {
        assert!(self.valid());
        Point {
            x: i64::from(p.x).clamp(i64::from(self.x), self.right() - 1) as i32,
            y: i64::from(p.y).clamp(i64::from(self.y), self.bottom() - 1) as i32,
        }
    }
}
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Key {
    pub adapter: u64,
    pub connector: u32,
    pub receiver: [u8; 16],
}
impl Key {
    pub fn same_port(self, other: Self) -> bool {
        self.adapter == other.adapter && self.connector == other.connector
    }
    pub fn persistable(self) -> bool {
        self.adapter != 0 && self.connector != 0 && self.receiver.iter().any(|v| *v != 0)
    }
}
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
#[repr(u8)]
pub enum Rotation {
    #[default]
    Normal,
    Clockwise90,
    Clockwise180,
    Clockwise270,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Viewport {
    pub origin: Point,
    pub pixel_w: u32,
    pub pixel_h: u32,
    pub scale: u32,
    pub rotation: Rotation,
}
/// Validated output geometry for a bounded region of local logical/native
/// pixels. Region owners admit their extents once, then use these pure point
/// mappings without repeating global-origin or layout validation per pixel.
#[derive(Clone, Copy, Debug)]
pub struct Projection {
    view: Viewport,
    logical: Rect,
}
impl Projection {
    pub fn logical(self) -> Rect {
        self.logical
    }
    pub fn pixel_width(self) -> usize {
        self.view.pixel_w as usize
    }
    /// Map a local logical cell to its native center sample. Coordinates come
    /// from the admitted logical rectangle, without the global output origin.
    #[inline(always)]
    pub fn native_pixel(self, x: usize, y: usize) -> (usize, usize) {
        let (width, height) = self.view.oriented();
        let u = (((2 * x + 1) * self.view.scale as usize) / (2 * SCALE_UNIT as usize))
            .min(width as usize - 1);
        let v = (((2 * y + 1) * self.view.scale as usize) / (2 * SCALE_UNIT as usize))
            .min(height as usize - 1);
        let (w, h) = (self.view.pixel_w as usize, self.view.pixel_h as usize);
        match self.view.rotation {
            Rotation::Normal => (u, v),
            Rotation::Clockwise90 => (v, h - 1 - u),
            Rotation::Clockwise180 => (w - 1 - u, h - 1 - v),
            Rotation::Clockwise270 => (w - 1 - v, u),
        }
    }
    /// Map an admitted native pixel to its local logical cell. This is point
    /// sampling; primitive edges and conservative damage have other rounding.
    #[inline(always)]
    pub fn logical_pixel(self, x: usize, y: usize) -> (usize, usize) {
        let (w, h) = (self.view.pixel_w as usize, self.view.pixel_h as usize);
        let (u, v) = match self.view.rotation {
            Rotation::Normal => (x, y),
            Rotation::Clockwise90 => (h - 1 - y, x),
            Rotation::Clockwise180 => (w - 1 - x, h - 1 - y),
            Rotation::Clockwise270 => (y, w - 1 - x),
        };
        (
            ((2 * u + 1) * SCALE_UNIT as usize) / (2 * self.view.scale as usize),
            ((2 * v + 1) * SCALE_UNIT as usize) / (2 * self.view.scale as usize),
        )
    }
}
impl Default for Viewport {
    fn default() -> Self {
        Self {
            origin: Point::default(),
            pixel_w: 0,
            pixel_h: 0,
            scale: SCALE_UNIT,
            rotation: Rotation::Normal,
        }
    }
}
impl Viewport {
    pub fn validate(self) -> Result<()> {
        if self.pixel_w == 0
            || self.pixel_h == 0
            || self.pixel_w > 65536
            || self.pixel_h > 65536
            || self.scale < 60
            || self.scale > 960
        {
            return Err(Error::Invalid);
        }
        if !self.logical_unchecked().valid() {
            return Err(Error::Bounds);
        }
        Ok(())
    }
    fn oriented(self) -> (u32, u32) {
        if matches!(
            self.rotation,
            Rotation::Clockwise90 | Rotation::Clockwise270
        ) {
            (self.pixel_h, self.pixel_w)
        } else {
            (self.pixel_w, self.pixel_h)
        }
    }
    fn logical_unchecked(self) -> Rect {
        let (w, h) = self.oriented();
        Rect {
            x: self.origin.x,
            y: self.origin.y,
            w: (w * SCALE_UNIT).div_ceil(self.scale),
            h: (h * SCALE_UNIT).div_ceil(self.scale),
        }
    }
    pub fn logical(self) -> Result<Rect> {
        self.validate()?;
        Ok(self.logical_unchecked())
    }
    pub fn projection(self) -> Result<Projection> {
        self.validate()?;
        Ok(Projection {
            view: self,
            logical: self.logical_unchecked(),
        })
    }
    pub fn physical(self, p: Point) -> Result<Point> {
        let projection = self.projection()?;
        let rect = projection.logical();
        if !rect.contains(p) {
            return Err(Error::Bounds);
        }
        let (x, y) = (
            (i64::from(p.x) - i64::from(rect.x)) as usize,
            (i64::from(p.y) - i64::from(rect.y)) as usize,
        );
        let (x, y) = projection.native_pixel(x, y);
        Ok(Point {
            x: x as i32,
            y: y as i32,
        })
    }
    pub fn from_physical(self, p: Point) -> Result<Point> {
        let projection = self.projection()?;
        let rect = projection.logical();
        if p.x < 0 || p.y < 0 || p.x as u32 >= self.pixel_w || p.y as u32 >= self.pixel_h {
            return Err(Error::Bounds);
        }
        let (x, y) = projection.logical_pixel(p.x as usize, p.y as usize);
        Ok(Point {
            x: (i64::from(rect.x) + x as i64) as i32,
            y: (i64::from(rect.y) + y as i64) as i32,
        })
    }
    pub fn physical_damage(self, damage: Rect) -> Result<Option<Rect>> {
        let rect = self.logical()?;
        if !damage.valid() {
            return Err(Error::Invalid);
        }
        let Some(clipped) = rect.intersection(damage) else {
            return Ok(None);
        };
        let (w, h) = self.oriented();
        let left = (i64::from(clipped.x) - i64::from(rect.x)) as u64;
        let top = (i64::from(clipped.y) - i64::from(rect.y)) as u64;
        let scale = u64::from(self.scale);
        let unit = u64::from(SCALE_UNIT);
        let x0 = (left * scale / unit).min(u64::from(w)) as i32;
        let y0 = (top * scale / unit).min(u64::from(h)) as i32;
        let x1 = ((left + u64::from(clipped.w)) * scale)
            .div_ceil(unit)
            .min(u64::from(w)) as i32;
        let y1 = ((top + u64::from(clipped.h)) * scale)
            .div_ceil(unit)
            .min(u64::from(h)) as i32;
        if x0 == x1 || y0 == y1 {
            return Ok(None);
        }
        let (w, h) = (self.pixel_w as i32, self.pixel_h as i32);
        let (x, y, rw, rh) = match self.rotation {
            Rotation::Normal => (x0, y0, x1 - x0, y1 - y0),
            Rotation::Clockwise90 => (y0, h - x1, y1 - y0, x1 - x0),
            Rotation::Clockwise180 => (w - x1, h - y1, x1 - x0, y1 - y0),
            Rotation::Clockwise270 => (w - y1, x0, y1 - y0, x1 - x0),
        };
        Ok(Some(Rect {
            x,
            y,
            w: rw as u32,
            h: rh as u32,
        }))
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Output {
    pub key: Key,
    pub view: Viewport,
    pub enabled: bool,
    pub primary: bool,
    pub clone_group: u8,
    pub refresh_millihz: u32,
}
impl Default for Output {
    fn default() -> Self {
        Self {
            key: Key::default(),
            view: Viewport::default(),
            enabled: true,
            primary: false,
            clone_group: 0,
            refresh_millihz: 0,
        }
    }
}
impl Output {
    pub fn interval(self) -> Option<u64> {
        if self.refresh_millihz == 0 {
            None
        } else {
            Some(1_000_000_000_000 / u64::from(self.refresh_millihz))
        }
    }
}
/// Only complete validated layouts can be queried. No mutable output slice
/// escapes this publication; callers stage a separate prospective Layout.
#[derive(Default)]
pub struct Layout {
    outputs: [Output; CAPACITY],
    count: usize,
    primary: usize,
    revision: u64,
}
impl Layout {
    pub fn new(values: &[Output], revision: u64) -> Result<Self> {
        if values.is_empty() {
            return Err(Error::Empty);
        }
        if values.len() > CAPACITY {
            return Err(Error::Capacity);
        }
        if revision == 0 {
            return Err(Error::Invalid);
        }
        let mut result = Self {
            count: values.len(),
            revision,
            ..Self::default()
        };
        let (mut enabled, mut primary_count) = (0, 0);
        let (mut left, mut top) = (i64::MAX, i64::MAX);
        let (mut right, mut bottom) = (i64::MIN, i64::MIN);
        for (i, &value) in values.iter().enumerate() {
            if value.key.connector == 0 || value.refresh_millihz > 1_000_000 {
                return Err(Error::Invalid);
            }
            if values[..i]
                .iter()
                .any(|other| value.key.same_port(other.key))
            {
                return Err(Error::Duplicate);
            }
            result.outputs[i] = value;
            if !value.enabled {
                if value.primary {
                    return Err(Error::Primary);
                }
                continue;
            }
            enabled += 1;
            let rect = value.view.logical()?;
            left = left.min(i64::from(rect.x));
            top = top.min(i64::from(rect.y));
            right = right.max(rect.right());
            bottom = bottom.max(rect.bottom());
            if right - left > i64::from(i32::MAX) || bottom - top > i64::from(i32::MAX) {
                return Err(Error::Bounds);
            }
            if value.primary {
                primary_count += 1;
                result.primary = i;
            }
            for other in &values[..i] {
                if !other.enabled {
                    continue;
                }
                let previous = other.view.logical()?;
                let clone = value.clone_group != 0 && value.clone_group == other.clone_group;
                if clone && rect != previous {
                    return Err(Error::Clone);
                }
                if !clone && rect.intersection(previous).is_some() {
                    return Err(Error::Overlap);
                }
            }
        }
        if enabled == 0 {
            return Err(Error::Empty);
        }
        if primary_count != 1 {
            return Err(Error::Primary);
        }
        Ok(result)
    }
    pub fn outputs(&self) -> &[Output] {
        &self.outputs[..self.count]
    }
    pub fn primary(&self) -> Option<usize> {
        (self.count != 0).then_some(self.primary)
    }
    pub fn revision(&self) -> u64 {
        self.revision
    }
    pub fn at(&self, p: Point) -> Option<usize> {
        if self.count == 0 {
            return None;
        }
        if self.outputs[self.primary]
            .view
            .logical_unchecked()
            .contains(p)
        {
            return Some(self.primary);
        }
        self.outputs()
            .iter()
            .position(|v| v.enabled && v.view.logical_unchecked().contains(p))
    }
    pub fn nearest(&self, p: Point) -> Option<(usize, Point)> {
        if let Some(index) = self.at(p) {
            return Some((index, p));
        }
        if self.count == 0 {
            return None;
        }
        let mut distance = u128::MAX;
        let mut best = self.primary;
        let mut closest = Point::default();
        for (i, value) in self.outputs().iter().enumerate() {
            if !value.enabled {
                continue;
            }
            let projected = value.view.logical_unchecked().project(p);
            let dx = i128::from(p.x) - i128::from(projected.x);
            let dy = i128::from(p.y) - i128::from(projected.y);
            let current = (dx * dx + dy * dy) as u128;
            if current < distance || (current == distance && i == self.primary) {
                distance = current;
                best = i;
                closest = projected;
            }
        }
        Some((best, closest))
    }
    pub fn dominant(&self, rect: Rect) -> Option<usize> {
        if self.count == 0 || !rect.valid() {
            return None;
        }
        let mut best = self.primary;
        let mut area = 0;
        for (i, value) in self.outputs().iter().enumerate() {
            if !value.enabled {
                continue;
            }
            if let Some(part) = rect.intersection(value.view.logical_unchecked()) {
                let current = u64::from(part.w) * u64::from(part.h);
                if current > area || (current == area && i == self.primary) {
                    best = i;
                    area = current;
                }
            }
        }
        Some(best)
    }
    pub fn rescue(&self, rect: Rect, title_height: u32) -> Result<Rect> {
        if !rect.valid() || title_height == 0 {
            return Err(Error::Invalid);
        }
        let best = self.dominant(rect).ok_or(Error::Empty)?;
        let title = Rect {
            h: rect.h.min(title_height),
            ..rect
        };
        for value in self.outputs() {
            if !value.enabled {
                continue;
            }
            let region = value.view.logical_unchecked();
            if let Some(part) = title.intersection(region) {
                if part.w >= 64.min(rect.w.min(region.w)) && part.h == title.h.min(region.h) {
                    return Ok(rect);
                }
            }
        }
        let target = self.outputs[best].view.logical_unchecked();
        let max_x = i64::from(target.x).max(target.right() - i64::from(rect.w));
        let max_y = i64::from(target.y).max(target.bottom() - i64::from(rect.h.min(target.h)));
        let result = Rect {
            x: i64::from(rect.x).clamp(i64::from(target.x), max_x) as i32,
            y: i64::from(rect.y).clamp(i64::from(target.y), max_y) as i32,
            ..rect
        };
        if !result.valid() {
            return Err(Error::Bounds);
        }
        Ok(result)
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    fn original_outputs() -> [Output; 2] {
        let key = Key {
            adapter: 0x10de250401000900,
            connector: 4,
            receiver: [1; 16],
        };
        [
            Output {
                key,
                primary: true,
                view: Viewport {
                    pixel_w: 3840,
                    pixel_h: 2160,
                    scale: 240,
                    ..Viewport::default()
                },
                refresh_millihz: 60_000,
                ..Output::default()
            },
            Output {
                key: Key {
                    connector: 8,
                    ..key
                },
                view: Viewport {
                    origin: Point { x: -1080, y: 0 },
                    pixel_w: 1920,
                    pixel_h: 1080,
                    rotation: Rotation::Clockwise90,
                    ..Viewport::default()
                },
                refresh_millihz: 100_000,
                ..Output::default()
            },
        ]
    }
    #[test]
    fn original_signed_layout_projection_rescue_and_refresh_cases() {
        let outputs = original_outputs();
        let layout = Layout::new(&outputs, 1).unwrap();
        assert_eq!(
            outputs[0].view.logical().unwrap(),
            Rect {
                x: 0,
                y: 0,
                w: 1920,
                h: 1080
            }
        );
        assert_eq!(
            outputs[1].view.logical().unwrap(),
            Rect {
                x: -1080,
                y: 0,
                w: 1080,
                h: 1920
            }
        );
        assert_eq!(
            outputs[1].view.physical(Point { x: -1080, y: 0 }).unwrap(),
            Point { x: 0, y: 1079 }
        );
        assert_eq!(
            outputs[1]
                .view
                .from_physical(Point { x: 0, y: 1079 })
                .unwrap(),
            Point { x: -1080, y: 0 }
        );
        assert_eq!(layout.at(Point { x: -1, y: 700 }), Some(1));
        assert_eq!(layout.at(Point { x: 0, y: 700 }), Some(0));
        assert_eq!(layout.at(Point { x: 0, y: 1080 }), None);
        assert_eq!(
            layout.nearest(Point { x: 500, y: 1200 }),
            Some((0, Point { x: 500, y: 1079 }))
        );
        assert_eq!(outputs[0].interval(), Some(16_666_666));
        assert_eq!(outputs[1].interval(), Some(10_000_000));
        let window = Rect {
            x: -900,
            y: 100,
            w: 600,
            h: 700,
        };
        assert_eq!(layout.rescue(window, 24).unwrap(), window);
        let unplugged = Layout::new(&outputs[..1], 2).unwrap();
        assert_eq!(
            unplugged.rescue(window, 24).unwrap(),
            Rect { x: 0, ..window }
        );
        assert_eq!(
            unplugged
                .rescue(
                    Rect {
                        x: -5000,
                        y: -3000,
                        w: 4000,
                        h: 3000
                    },
                    24
                )
                .unwrap(),
            Rect {
                x: 0,
                y: 0,
                w: 4000,
                h: 3000
            }
        );
        let mut clone = outputs;
        clone[0].clone_group = 1;
        clone[1].clone_group = 1;
        clone[1].view = Viewport {
            pixel_w: 1920,
            pixel_h: 1080,
            ..Viewport::default()
        };
        let mirrored = Layout::new(&clone, 3).unwrap();
        assert_eq!(mirrored.at(Point { x: 700, y: 900 }), Some(0));
        assert_ne!(clone[0].interval(), clone[1].interval());
        clone[1].view.origin.x = 1;
        assert!(matches!(Layout::new(&clone, 4), Err(Error::Clone)));
        clone[0].clone_group = 0;
        clone[1].clone_group = 0;
        assert!(matches!(Layout::new(&clone, 4), Err(Error::Overlap)));
        clone = outputs;
        clone[1].key = clone[0].key;
        assert!(matches!(Layout::new(&clone, 4), Err(Error::Duplicate)));
        clone = outputs;
        clone[1].primary = true;
        assert!(matches!(Layout::new(&clone, 4), Err(Error::Primary)));
        clone = outputs;
        clone[0].enabled = false;
        assert!(matches!(Layout::new(&clone, 4), Err(Error::Primary)));
    }
    #[test]
    fn original_exclusive_edges_and_extreme_spanning_layout_refusals() {
        let outputs = original_outputs();
        let mut invalid = outputs[0].view;
        invalid.scale = 0;
        assert_eq!(invalid.logical(), Err(Error::Invalid));
        invalid = outputs[0].view;
        invalid.origin.x = i32::MAX;
        assert_eq!(invalid.logical(), Err(Error::Bounds));
        invalid = Viewport {
            origin: Point {
                x: i32::MAX - 127,
                y: 0,
            },
            pixel_w: 128,
            pixel_h: 1,
            ..Viewport::default()
        };
        assert_eq!(invalid.logical(), Err(Error::Bounds));
        let mut distant = outputs;
        distant[0].view = Viewport {
            origin: Point { x: i32::MIN, y: 0 },
            pixel_w: 640,
            pixel_h: 480,
            ..Viewport::default()
        };
        distant[1].view = Viewport {
            origin: Point {
                x: i32::MAX - 640,
                y: 0,
            },
            pixel_w: 640,
            pixel_h: 480,
            ..Viewport::default()
        };
        assert!(matches!(Layout::new(&distant, 1), Err(Error::Bounds)));
        assert!(
            !Rect {
                x: i32::MIN,
                y: 0,
                w: u32::MAX,
                h: 1
            }
            .valid()
        );
        let edge = Viewport {
            origin: Point {
                x: i32::MAX - 640,
                y: i32::MAX - 480,
            },
            pixel_w: 640,
            pixel_h: 480,
            ..Viewport::default()
        };
        assert_eq!(edge.logical().unwrap().right(), i64::from(i32::MAX));
    }
    #[test]
    fn original_fractional_rotated_native_pixel_damage_matrix() {
        let fractional = Viewport {
            origin: Point { x: -2560, y: -1440 },
            pixel_w: 3840,
            pixel_h: 2160,
            scale: 180,
            ..Viewport::default()
        };
        assert_eq!(
            fractional.logical().unwrap(),
            Rect {
                x: -2560,
                y: -1440,
                w: 2560,
                h: 1440
            }
        );
        assert_eq!(
            fractional
                .physical_damage(Rect {
                    x: -2559,
                    y: -1439,
                    w: 1,
                    h: 1
                })
                .unwrap(),
            Some(Rect {
                x: 1,
                y: 1,
                w: 2,
                h: 2
            })
        );
        for rotation in [
            Rotation::Normal,
            Rotation::Clockwise90,
            Rotation::Clockwise180,
            Rotation::Clockwise270,
        ] {
            for scale in [60, 120, 150, 180, 240] {
                let view = Viewport {
                    origin: Point { x: -13, y: 29 },
                    pixel_w: 17,
                    pixel_h: 11,
                    scale,
                    rotation,
                };
                let full = view.logical().unwrap();
                assert_eq!(
                    view.physical_damage(full).unwrap(),
                    Some(Rect {
                        x: 0,
                        y: 0,
                        w: 17,
                        h: 11
                    })
                );
                for y in 0..11 {
                    for x in 0..17 {
                        let native = Point { x, y };
                        let logical = view.from_physical(native).unwrap();
                        assert!(full.contains(logical));
                        assert!(
                            view.physical_damage(Rect {
                                x: logical.x,
                                y: logical.y,
                                w: 1,
                                h: 1
                            })
                            .unwrap()
                            .unwrap()
                            .contains(native)
                        );
                        let center = view.physical(logical).unwrap();
                        assert!(center.x >= 0 && center.x < 17 && center.y >= 0 && center.y < 11);
                        if scale >= 120 {
                            assert_eq!(view.from_physical(center).unwrap(), logical);
                        }
                    }
                }
            }
        }
    }
}
