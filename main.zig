const std = @import("std");

pub fn main() !void {
    const builder = Person.builder()
        .set_name("John") ///// required, non-idempotent
        .set_age(30) ////////// required, non-idempotent
        .set_partner("Mary") // optional, non-idempotent
        .set_dead(); ////////// optional, idempotent

    const person = builder.build();

    std.debug.print("   name: {s}\n", .{person.name});
    std.debug.print("    age: {}\n", .{person.age});
    std.debug.print("partner: {s}\n", .{person.partner orelse "none"});
    std.debug.print("   dead: {}\n", .{person.is_dead});
}

const Name = []const u8;

const Person = struct {
    name: Name,
    age: u8,
    partner: ?Name,
    is_dead: bool,

    pub fn builder() PersonBuilder(false, false, false) {
        return .{
            .name = null,
            .age = null,
            .partner = null,
            .is_dead = false,
        };
    }
};

fn PersonBuilder(has_name: bool, has_age: bool, has_partner: bool) type {
    return struct {
        const Self = @This();

        name: ?Name,
        age: ?u8,
        partner: ?Name,
        is_dead: bool,

        pub fn build(self: *const Self) Person {
            if (!has_name) {
                @compileError("missing value for `name`");
            }
            if (!has_age) {
                @compileError("missing value for `age`");
            }
            return .{
                .name = self.name orelse unreachable,
                .age = self.age orelse unreachable,
                .partner = self.partner,
                .is_dead = self.is_dead,
            };
        }

        pub fn set_name(self: *const Self, name: Name) PersonBuilder(true, has_age, has_partner) {
            if (has_name) {
                @compileError("duplicate value for `name`");
            }
            return .{
                .name = name,
                .age = self.age,
                .partner = self.partner,
                .is_dead = self.is_dead,
            };
        }

        pub fn set_age(self: *const Self, age: u8) PersonBuilder(has_name, true, has_partner) {
            if (has_age) {
                @compileError("duplicate value for `age`");
            }
            return .{
                .name = self.name,
                .age = age,
                .partner = self.partner,
                .is_dead = self.is_dead,
            };
        }

        pub fn set_partner(self: *const Self, partner: Name) PersonBuilder(has_name, has_age, true) {
            if (has_partner) {
                @compileError("duplicate value for `partner`");
            }
            return .{
                .name = self.name,
                .age = self.age,
                .partner = partner,
                .is_dead = self.is_dead,
            };
        }

        pub fn set_dead(self: *const Self) PersonBuilder(has_name, has_age, has_partner) {
            return .{
                .name = self.name,
                .age = self.age,
                .partner = self.partner,
                .is_dead = true,
            };
        }
    };
}
