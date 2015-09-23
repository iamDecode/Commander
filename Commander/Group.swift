public enum GroupError : ErrorType, CustomStringConvertible {
  /// No-subcommand was found with the given name
  case UnknownCommand(String)

  /// No command was given
  /// :param: The current path to the command (i.e, all the group names)
  /// :param: The group raising the error
  case NoCommand(String?, Group)

  public var description:String {
    switch self {
    case .UnknownCommand(let name):
      return "Unknown command: `\(name)`"
    case .NoCommand(let path, let group):
      let available = group.commands.keys.joinWithSeparator(", ")
      if let path = path {
        return "Usage: \(path) COMMAND\n\nCommands: \(available)"
      } else {
        return "Commands: \(available)"
      }
    }
  }
}

/// Represents a group of commands
public class Group : CommandType {
  var commands = [String:CommandType]()

  /// Create a new group
  public init() {}

  /// Add a named sub-command to the group
  public func addCommand(name:String, _ command:CommandType) {
    commands[name] = command
  }

  /// Run the group command
  public func run(parser:ArgumentParser) throws {
    if let name = parser.shift() {
      if let command = commands[name] {
        do {
          try command.run(parser)
        } catch GroupError.UnknownCommand(let childName) {
          throw GroupError.UnknownCommand("\(name) \(childName)")
        } catch GroupError.NoCommand(let path, let group) {
          if let path = path {
            throw GroupError.NoCommand("\(name) \(path)", group)
          }

          throw GroupError.NoCommand(name, group)
        }
      } else {
        throw GroupError.UnknownCommand(name)
      }
    } else {
      throw GroupError.NoCommand(nil, self)
    }
  }
}

extension Group {
  public convenience init(closure:Group -> ()) {
    self.init()
    closure(self)
  }

  /// Add a sub-group using a closure
  public func group(name:String, closure:Group -> ()) {
    addCommand(name, Group(closure: closure))
  }

  /// Add a command using a closure
  public func command(name:String, closure:() -> ()) {
    addCommand(name, AnonymousCommand { parser in closure() })
  }

  /// Add a command which takes one argument using a closure
  public func command<A:ArgumentConvertible>(name:String, closure:A -> ()) {
    addCommand(name, Commander.command(closure))
  }

  /// Add a command which takes two argument using a closure
  public func command<A:ArgumentConvertible, B:ArgumentConvertible>(name:String, closure:(A,B) -> ()) {
    addCommand(name, Commander.command(closure))
  }

  /// Add a command which takes three argument using a closure
  public func command<A:ArgumentConvertible, B:ArgumentConvertible, C:ArgumentConvertible>(name:String, closure:(A,B,C) -> ()) {
    addCommand(name, Commander.command(closure))
  }
}