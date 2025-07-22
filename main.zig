const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const builder = Person.builder(gpa.allocator())
        .set_name("John") ///// required, oneshot
        .set_age(30) ////////// required, oneshot
        .set_partner("Mary") // optional, oneshot
        .add_friend("Gary") //  optional, cumulative
        .add_friend("Mark") //
        .set_dead(); ////////// optional, non-cumulative

    const person = builder.build();
    defer person.deinit();

    person.display();
}

const Name = []const u8;

const Person = struct {
    const Self = @This();

    name: Name,
    age: u8,
    partner: ?Name,
    friends: std.ArrayList(Name),
    is_dead: bool,

    pub fn builder(allocator: std.mem.Allocator) PersonBuilder(false, false, false) {
        return .{
            .name = undefined,
            .age = undefined,
            .partner = null,
            .friends = std.ArrayList(Name).init(allocator),
            .is_dead = false,
        };
    }

    pub fn deinit(self: *const Self) void {
        self.friends.deinit();
    }

    pub fn display(self: *const Self) void {
        std.debug.print("   name: {s}\n", .{self.name});
        std.debug.print("    age: {}\n", .{self.age});
        std.debug.print("partner: {s}\n", .{self.partner orelse "none"});
        std.debug.print("   dead: {}\n", .{self.is_dead});

        std.debug.print("friends: ", .{});
        for (self.friends.items, 0..) |friend, i| {
            if (i > 0) {
                std.debug.print(", ", .{});
            }
            std.debug.print("{s}", .{friend});
        }
        std.debug.print("\n", .{});
    }
};

fn PersonBuilder(has_name: bool, has_age: bool, has_partner: bool) type {
    return struct {
        const Self = @This();

        name: Name,
        age: u8,
        partner: ?Name,
        friends: std.ArrayList(Name),
        is_dead: bool,

        pub fn build(self: *const Self) Person {
            if (!has_name) {
                @compileError("missing value for `name`");
            }
            if (!has_age) {
                @compileError("missing value for `age`");
            }
            return .{
                .name = self.name,
                .age = self.age,
                .partner = self.partner,
                .friends = self.friends,
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
                .friends = self.friends,
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
                .friends = self.friends,
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
                .friends = self.friends,
                .is_dead = self.is_dead,
            };
        }

        pub fn set_dead(self: *const Self) PersonBuilder(has_name, has_age, has_partner) {
            return .{
                .name = self.name,
                .age = self.age,
                .partner = self.partner,
                .friends = self.friends,
                .is_dead = true,
            };
        }

        pub fn add_friend(self: *const Self, friend: Name) PersonBuilder(has_name, has_age, has_partner) {
            var friends = self.friends;
            friends.append(friend) catch @panic("alloc failed");
            return .{
                .name = self.name,
                .age = self.age,
                .partner = self.partner,
                .friends = friends,
                .is_dead = self.is_dead,
            };
        }
    };
}
